import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_list_card.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _routeFilter;
  CustomerListFilter _filter = CustomerListFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<WaterPlantRepository>()
          .loadCustomersForCurrentAdminFromFirestore();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Customer> _list(WaterPlantRepository repo) {
    final month = DateTime.now();
    final all = List<Customer>.from(repo.searchCustomers(_query))
      ..sort((a, b) => a.name.compareTo(b.name));

    final routeFiltered = _routeFilter == null
        ? all
        : (_routeFilter == unassignedRouteFilter
              ? all
                    .where((c) => c.routeId == null || c.routeId!.isEmpty)
                    .toList()
              : all.where((c) => c.routeId == _routeFilter).toList());

    if (_filter == CustomerListFilter.all) return routeFiltered;

    return routeFiltered.where((c) {
      final category = _categoryFor(repo, c, month);
      return switch (_filter) {
        CustomerListFilter.pending =>
          category == CustomerPaymentCategory.pending,
        CustomerListFilter.paid => category == CustomerPaymentCategory.paid,
        CustomerListFilter.overdue =>
          category == CustomerPaymentCategory.overdue,
        CustomerListFilter.all => true,
      };
    }).toList();
  }

  void _showManageRoutes(BuildContext context, WaterPlantRepository repo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ManageRoutesSheet(repo: repo),
    );
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

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomersHeader(
                  onAdd: () => context.push('/customers/add'),
                  onMenu: () => context.go(AppRoutes.more),
                ),
                CustomersSearchRow(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                ),
                CustomersListPanel(
                  child: Column(
                    children: [
                      CustomerRouteFilter(
                        routes: repo.deliveryRoutes,
                        selected: _routeFilter,
                        onSelected: (routeId) =>
                            setState(() => _routeFilter = routeId),
                        onManageRoutes: () => _showManageRoutes(context, repo),
                      ),
                      CustomersFilterChips(
                        selected: _filter,
                        onSelected: (f) => setState(() => _filter = f),
                      ),
                      Expanded(
                        child: customers.isEmpty
                            ? _EmptyCustomers(
                                isSearch:
                                    _query.isNotEmpty ||
                                    _routeFilter != null ||
                                    _filter != CustomerListFilter.all,
                                onAdd: () => context.push('/customers/add'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  16,
                                ),
                                itemCount: customers.length,
                                itemBuilder: (_, i) {
                                  final c = customers[i];
                                  final monthly = repo.monthlyStatsForCustomer(
                                    c.id,
                                    month,
                                  );
                                  final deliveries = repo.deliveriesForCustomer(
                                    c.id,
                                  );
                                  final last = deliveries.isEmpty
                                      ? null
                                      : deliveries.first.date;
                                  final idx = repo.customers.indexWhere(
                                    (x) => x.id == c.id,
                                  );
                                  return CustomerListCard(
                                    customer: c,
                                    colorIndex: idx >= 0 ? idx : i,
                                    unitsThisMonth: monthly.totalUnits,
                                    lastDeliveryLabel:
                                        lastDeliveryRelativeLabel(last),
                                    balance: repo
                                        .customerBalance(c.id)
                                        .clamp(0, double.infinity),
                                    category: _categoryFor(repo, c, month),
                                    onTap: () =>
                                        context.push('/customers/${c.id}'),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ManageRoutesSheet extends StatefulWidget {
  const _ManageRoutesSheet({required this.repo});

  final WaterPlantRepository repo;

  @override
  State<_ManageRoutesSheet> createState() => _ManageRoutesSheetState();
}

class _ManageRoutesSheetState extends State<_ManageRoutesSheet> {
  final _controller = TextEditingController();
  late List<DeliveryRoute> _routes;

  @override
  void initState() {
    super.initState();
    _routes = widget.repo.deliveryRoutes;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addRoute() {
    try {
      widget.repo.addDeliveryRoute(_controller.text);
      _controller.clear();
      if (!mounted) return;
      setState(() => _routes = widget.repo.deliveryRoutes);
      FocusScope.of(context).unfocus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ArgumentError ? e.message.toString() : 'Route not added',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CustomersColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Delivery Routes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CustomersColors.titleNavy,
              ),
            ),
            const SizedBox(height: 12),
            if (_routes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No routes created yet.',
                  style: GoogleFonts.poppins(
                    color: CustomersColors.labelGrey,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _routes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final route = _routes[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.route_rounded,
                        color: CustomersColors.addButton,
                      ),
                      title: Text(
                        route.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Add route name, e.g. Route 4',
                prefixIcon: const Icon(Icons.add_road_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _addRoute(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _addRoute,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Route'),
              style: FilledButton.styleFrom(
                backgroundColor: CustomersColors.addButton,
              ),
            ),
          ],
        ),
      ),
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
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: CustomersColors.labelGrey,
            ),
          ),
          if (!isSearch) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Customer'),
              style: FilledButton.styleFrom(
                backgroundColor: CustomersColors.addButton,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
