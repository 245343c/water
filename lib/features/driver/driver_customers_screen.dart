import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_list_card.dart';
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
        final totalAssigned = assignedCustomers.length;
        final routes = _routesFor(assignedCustomers, repo);
        final hasUnassigned = assignedCustomers.any(_isUnassignedRoute);
        final month = DateTime.now();
        final customers = List<Customer>.of(
          repo.searchCustomersForDriver(driverId, _query),
        ).where(_matchesRoute).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return Scaffold(
          backgroundColor: DriverColors.screenBg,
          body: DriverScaffold(
            child: Column(
              children: [
                DriverHeader(
                  title: 'Customers',
                  subtitle: assignedShop == null
                      ? 'Driver is not linked to a water plant'
                      : '${assignedShop.name} - $totalAssigned assigned customers',
                ),
                DriverRouteFilter(
                  routes: routes,
                  selected: _routeFilter,
                  showUnassigned: hasUnassigned,
                  onSelected: (routeId) =>
                      setState(() => _routeFilter = routeId),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: DriverColors.cardDecoration,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: DriverColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            assignedShop == null
                                ? 'Only customers from the assigned plant will appear here.'
                                : 'Showing customers linked to ${assignedShop.name} only.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: DriverColors.labelGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search name or phone…',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: DriverColors.labelGrey),
                      prefixIcon: const Icon(Icons.search_rounded, color: DriverColors.accent),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: DriverColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: DriverColors.cardBorder),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: customers.isEmpty
                      ? Center(
                          child: Text(
                            'No customers found',
                            style: GoogleFonts.poppins(color: DriverColors.labelGrey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                          itemCount: customers.length,
                          itemBuilder: (_, i) {
                            final c = customers[i];
                            final monthly = repo.monthlyStatsForCustomer(c.id, month);
                            final deliveries = repo.deliveriesForCustomer(c.id);
                            final last = deliveries.isEmpty ? null : deliveries.first.date;
                            final idx = repo.customers.indexWhere((x) => x.id == c.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: CustomerListCard(
                                customer: c,
                                colorIndex: idx >= 0 ? idx : i,
                                unitsThisMonth: monthly.totalUnits,
                                lastDeliveryLabel: lastDeliveryRelativeLabel(last),
                                balance: 0,
                                category: CustomerPaymentCategory.paid,
                                onTap: () => context.push('/driver/customers/${c.id}'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
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
