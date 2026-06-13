import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/customer_display_localization.dart';
import 'package:sri_sai_ro_water/core/localization/delivery_localization.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
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
  late final NotificationRepository _notifications;
  bool _refreshingDriverOrders = false;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationRepository>();
    _notifications.addListener(_onDriverNotificationsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _refreshDriverData();
    });
  }

  @override
  void dispose() {
    _notifications.removeListener(_onDriverNotificationsChanged);
    _search.dispose();
    super.dispose();
  }

  void _onDriverNotificationsChanged() {
    unawaited(_hydrateDriverOrdersFromNotifications());
  }

  Future<void> _refreshDriverData() async {
    final repo = context.read<WaterPlantRepository>();
    final auth = context.read<AuthRepository>();
    final driverId = auth.currentUser?.driverId;
    await repo.loadDeliveryRoutesForCurrentAdmin();
    await repo.loadCustomersForCurrentAdminFromFirestore(force: true);
    await repo.loadLedgerForCurrentShopFromFirestore(force: true);
    await repo.hydrateDriverOpenOrders(driverId: driverId);
    await _hydrateDriverOrdersFromNotifications(driverId: driverId);
  }

  Future<void> _hydrateDriverOrdersFromNotifications({String? driverId}) async {
    if (_refreshingDriverOrders || !mounted) return;
    _refreshingDriverOrders = true;
    try {
      final repo = context.read<WaterPlantRepository>();
      final auth = context.read<AuthRepository>();
      final resolvedDriverId = driverId ?? auth.currentUser?.driverId;
      final orderIds = _notifications
          .forDriver(driverId: resolvedDriverId)
          .map((n) => n.orderId)
          .whereType<String>()
          .where((id) => id.isNotEmpty);
      await repo.hydrateDriverOrdersFromNotifications(
        orderIds,
        driverId: resolvedDriverId,
      );
    } finally {
      _refreshingDriverOrders = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WaterPlantRepository, AuthRepository>(
      builder: (context, repo, auth, _) {
        final driverId = auth.currentUser?.driverId;
        final assignedShop = repo.shopForDriver(driverId);
        final assignedCustomers = repo.customersForDriver(driverId);
        final routes = repo.deliveryRoutesForDriver(driverId);
        final hasUnassigned = repo.driverUnassignedCustomerCount(driverId) > 0;
        final instantOrders = repo.driverInstantOrders(driverId: driverId);
        final strings = context.l10n;

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
          ..sort(
            (a, b) => a
                .driverDisplayName(strings)
                .compareTo(b.driverDisplayName(strings)),
          );

        return Scaffold(
          backgroundColor: DriverColors.contentBg,
          body: Column(
            children: [
              DriverCustomersToolbar(
                title: strings.customers,
                subtitle: assignedShop == null
                    ? null
                    : '${assignedShop.name} · ${assignedCustomers.length}',
                searchController: _search,
                onSearchChanged: (v) => setState(() => _query = v),
              ),
              if (instantOrders.isNotEmpty)
                _InstantOrdersBanner(
                  orders: instantOrders,
                  onOpen: () => context.go('/driver/route'),
                ),
              if (routes.isNotEmpty || hasUnassigned)
                DriverRouteFilter(
                  routes: routes,
                  selected: _routeFilter,
                  showUnassigned: hasUnassigned,
                  allCustomerCount: assignedCustomers.length,
                  unassignedCustomerCount:
                      repo.driverUnassignedCustomerCount(driverId),
                  customerCountForRoute: (routeId) =>
                      repo.driverCustomerCountOnRoute(driverId, routeId),
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
                          strings.noCustomersFound,
                          style: GoogleFonts.poppins(
                            color: DriverColors.labelGrey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: customers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
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
                            pendingOrder: repo.acceptedOrderForCustomer(
                              c.id,
                              driverId: driverId,
                            ),
                            emptyJarsWithCustomer:
                                repo.customerCanBalance(c.id).totalWithCustomer,
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

class _InstantOrdersBanner extends StatelessWidget {
  const _InstantOrdersBanner({required this.orders, required this.onOpen});

  final List<CustomerOrder> orders;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final latest = orders.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Material(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DriverColors.accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DriverColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: DriverColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.instantOrdersWaiting(orders.length),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: DriverColors.titleNavy,
                        ),
                      ),
                      Text(
                        context.l10n.orderItemsSummary(latest),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: DriverColors.labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.open,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: DriverColors.accent,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DriverColors.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
