import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/core/constants/delivery_route_constants.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_list_card.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/routes/widgets/delivery_routes_widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController();
  String _query = '';
  CustomerListFilter _filter = CustomerListFilter.all;
  String? _routeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<WaterPlantRepository>().loadDeliveryRoutesForCurrentAdmin();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Customer> _searched(WaterPlantRepository repo) {
    return List<Customer>.from(repo.searchCustomers(_query))
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<Customer> _applyPaymentFilter(
    List<Customer> customers,
    WaterPlantRepository repo,
    CustomerListFilter filter,
  ) {
    if (filter == CustomerListFilter.all) return customers;
    final month = DateTime.now();
    return customers.where((c) {
      final category = _categoryFor(repo, c, month);
      return switch (filter) {
        CustomerListFilter.pending =>
          category == CustomerPaymentCategory.pending,
        CustomerListFilter.paid => category == CustomerPaymentCategory.paid,
        CustomerListFilter.overdue =>
          category == CustomerPaymentCategory.overdue,
        CustomerListFilter.all => true,
      };
    }).toList();
  }

  List<Customer> _applyRouteFilter(
    List<Customer> customers,
    String? routeFilter,
  ) {
    if (routeFilter == null) return customers;
    if (routeFilter == DeliveryRouteFilters.unassigned) {
      return customers
          .where((c) => c.routeId == null || c.routeId!.trim().isEmpty)
          .toList();
    }
    return customers.where((c) => c.routeId == routeFilter).toList();
  }

  List<Customer> _list(WaterPlantRepository repo) {
    final searched = _searched(repo);
    return _applyRouteFilter(
      _applyPaymentFilter(searched, repo, _filter),
      _routeFilter,
    );
  }

  Map<CustomerListFilter, int> _paymentCounts(WaterPlantRepository repo) {
    final scoped = _applyRouteFilter(_searched(repo), _routeFilter);
    return {
      for (final f in CustomerListFilter.values)
        f: _applyPaymentFilter(scoped, repo, f).length,
    };
  }

  Map<String?, int> _routeCounts(WaterPlantRepository repo) {
    final scoped = _applyPaymentFilter(_searched(repo), repo, _filter);
    final counts = <String?, int>{
      null: scoped.length,
      DeliveryRouteFilters.unassigned: scoped
          .where((c) => c.routeId == null || c.routeId!.trim().isEmpty)
          .length,
    };
    for (final route in repo.activeDeliveryRoutes) {
      counts[route.id] =
          scoped.where((c) => c.routeId == route.id).length;
    }
    return counts;
  }

  Future<String?> _createRouteFromFilter(
    WaterPlantRepository repo,
  ) async {
    final name = await showDeliveryRouteNameDialog(
      context,
      title: 'Create route',
      confirmLabel: 'Create',
    );
    if (name == null || name.isEmpty || !mounted) return null;
    try {
      final route = await repo.addDeliveryRoute(name);
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route "${route.name}" created', style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return route.id;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('ArgumentError: ', ''),
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  CustomerPaymentCategory _categoryFor(
    WaterPlantRepository repo,
    Customer c,
    DateTime month,
  ) {
    final monthly = repo.monthlyStatsForCustomer(c.id, month);
    final prior = repo.previousBalanceForMonth(c.id, month);
    final total = repo.customerBalance(c.id);
    return customerPaymentCategory(
      totalBalance: total,
      monthBalance: monthly.balance,
      priorBalance: prior,
      monthTotal: monthly.totalAmount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customers = _list(repo);
        final month = DateTime.now();
        void openAddCustomer() => context.push('/customers/add');

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            usePageGradient: true,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomersHeader(
                    icon: Icons.people_rounded,
                    showAddButton: false,
                    onAdd: openAddCustomer,
                    searchController: _search,
                    onSearchChanged: (v) => setState(() => _query = v),
                  ),
                  CustomersDualFilterBar(
                    routes: repo.activeDeliveryRoutes,
                    selectedRouteId: _routeFilter,
                    selectedPayment: _filter,
                    routeCounts: _routeCounts(repo),
                    paymentCounts: _paymentCounts(repo),
                    onRouteChanged: (id) => setState(() => _routeFilter = id),
                    onPaymentChanged: (f) => setState(() => _filter = f),
                    onCreateRouteRequested: () => _createRouteFromFilter(repo),
                    routeCountsFor: _routeCounts,
                    onRouteRemoved: (routeId) => setState(() {
                      if (_routeFilter == routeId) _routeFilter = null;
                    }),
                  ),
                  Expanded(
                    child: customers.isEmpty
                        ? _EmptyCustomers(
                            isSearch: _query.isNotEmpty ||
                                _filter != CustomerListFilter.all ||
                                _routeFilter != null,
                            onAdd: openAddCustomer,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                            itemCount: customers.length,
                            itemBuilder: (_, i) {
                              final c = customers[i];
                              final monthly = repo.monthlyStatsForCustomer(c.id, month);
                              final deliveries = repo.deliveriesForCustomer(c.id);
                              final last = deliveries.isEmpty ? null : deliveries.first.date;
                              final idx = repo.customers.indexWhere((x) => x.id == c.id);
                              final routeName = repo.deliveryRouteName(c.routeId);
                              final unassigned =
                                  c.routeId == null || c.routeId!.trim().isEmpty;
                              return CustomerListCard(
                                customer: c,
                                colorIndex: idx >= 0 ? idx : i,
                                unitsThisMonth: monthly.totalUnits,
                                lastDeliveryLabel: lastDeliveryRelativeLabel(last),
                                balance: repo.customerBalance(c.id).clamp(0, double.infinity),
                                category: _categoryFor(repo, c, month),
                                routeName: unassigned ? 'No route' : routeName,
                                routeUnassigned: unassigned,
                                onTap: () => context.push('/customers/${c.id}'),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: CustomersAddButton(onPressed: openAddCustomer),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.isSearch, required this.onAdd});

  final bool isSearch;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 56,
              color: CustomersColors.labelGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              isSearch ? 'No customers match your filters' : 'No customers yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: CustomersColors.labelGrey,
              ),
            ),
            if (!isSearch) ...[
              const SizedBox(height: 8),
              Text(
                'Tap Add customer below',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: CustomersColors.labelGrey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
