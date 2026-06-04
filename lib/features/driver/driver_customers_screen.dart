import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_list_card.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

class DriverCustomersScreen extends StatefulWidget {
  const DriverCustomersScreen({super.key});

  @override
  State<DriverCustomersScreen> createState() => _DriverCustomersScreenState();
}

class _DriverCustomersScreenState extends State<DriverCustomersScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _routeFilter;
  DriverCustomerListFilter _listFilter = DriverCustomerListFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = context.read<WaterPlantRepository>();
      await repo.loadCustomersForCurrentAdminFromFirestore();
      await repo.loadLedgerForCurrentShopFromFirestore();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WaterPlantRepository, AuthRepository>(
      builder: (context, repo, auth, _) {
        final driverId = auth.currentUser?.driverId;
        final assignedShop = repo.shopForDriver(driverId);
        final assignedCustomers = repo.customersForDriver(driverId);
        final routes = _routesFor(assignedCustomers, repo);
        final hasUnassigned = assignedCustomers.any(_isUnassignedRoute);

        var customers = List<Customer>.of(
          repo.searchCustomersForDriver(driverId, _query),
        ).where(_matchesRoute).toList();

        customers = customers.where((c) {
          final done = repo.hasDeliveryToday(c.id);
          return switch (_listFilter) {
            DriverCustomerListFilter.all => true,
            DriverCustomerListFilter.pendingToday => !done,
            DriverCustomerListFilter.deliveredToday => done,
          };
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Scaffold(
          backgroundColor: DriverColors.contentBg,
          body: Column(
            children: [
              DriverCustomersToolbar(
                title: 'Customers',
                subtitle: assignedShop == null
                    ? null
                    : '${assignedShop.name} · ${assignedCustomers.length}',
                searchController: _search,
                onSearchChanged: (v) => setState(() => _query = v),
              ),
              if (routes.isNotEmpty || hasUnassigned)
                DriverRouteFilter(
                  routes: routes,
                  selected: _routeFilter,
                  showUnassigned: hasUnassigned,
                  onSelected: (id) => setState(() => _routeFilter = id),
                ),
              DriverCustomersFilterChips(
                selected: _listFilter,
                onSelected: (f) => setState(() => _listFilter = f),
              ),
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: GoogleFonts.poppins(
                            color: DriverColors.labelGrey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = customers[i];
                          final deliveries = repo.deliveriesForCustomer(c.id);
                          final last = deliveries.isEmpty
                              ? null
                              : deliveries.first.date;
                          return DriverCustomerListCard(
                            customer: c,
                            lastDeliveryLabel: lastDeliveryRelativeLabel(last),
                            deliveredToday: repo.hasDeliveryToday(c.id),
                            onTap: () =>
                                context.push('/driver/customers/${c.id}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<DeliveryRoute> _routesFor(
    List<Customer> customers,
    WaterPlantRepository repo,
  ) {
    final routeIds = customers
        .map((c) => c.routeId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    return repo.deliveryRoutes
        .where((route) => routeIds.contains(route.id))
        .toList();
  }

  bool _matchesRoute(Customer customer) {
    if (_routeFilter == null) return true;
    if (_routeFilter == driverUnassignedRouteFilter) {
      return _isUnassignedRoute(customer);
    }
    return customer.routeId == _routeFilter;
  }

  bool _isUnassignedRoute(Customer customer) =>
      customer.routeId == null || customer.routeId!.trim().isEmpty;
}
