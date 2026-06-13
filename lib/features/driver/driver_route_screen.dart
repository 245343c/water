import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/customer_display_localization.dart';
import 'package:sri_sai_ro_water/core/localization/delivery_localization.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/app_notification.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/core/config/app_config.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_instant_delivery_card.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_route_widgets.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Driver home: accepted customer requests + today's route + completed.
class DriverRouteScreen extends StatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  String? _routeFilter;
  late final NotificationRepository _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationRepository>();
    _notifications.addListener(_refreshDriverOrders);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _refreshDriverOrders();
      if (!mounted) return;
      if (AppConfig.useInstantDispatchMock) {
        context.read<WaterPlantRepository>().restoreMockInstantDispatchForDriver();
      }
    });
  }

  @override
  void dispose() {
    _notifications.removeListener(_refreshDriverOrders);
    super.dispose();
  }

  Future<void> _refreshDriverOrders() async {
    if (!mounted) return;
    final repo = context.read<WaterPlantRepository>();
    final auth = context.read<AuthRepository>();
    final driverId = auth.currentUser?.driverId;
    await repo.loadDeliveryRoutesForCurrentAdmin();
    await repo.loadCustomersForCurrentAdminFromFirestore(force: true);
    await repo.loadLedgerForCurrentShopFromFirestore(force: true);
    await repo.hydrateDriverOpenOrders(driverId: driverId);
    final orderIds = _notifications
        .forDriver(driverId: driverId)
        .map((n) => n.orderId)
        .whereType<String>()
        .where((id) => id.isNotEmpty);
    await repo.hydrateDriverOrdersFromNotifications(
      orderIds,
      driverId: driverId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      WaterPlantRepository,
      NotificationRepository,
      AuthRepository
    >(
      builder: (context, repo, notifications, auth, _) {
        final driverId = auth.currentUser?.driverId;
        final assignedShop = repo.shopForDriver(driverId);
        final today = DateTime.now();
        final deliveries = repo
            .deliveriesOnDateForDriver(today, driverId)
            .where((delivery) => _deliveryMatchesRoute(delivery, repo))
            .toList();
        final assignedCustomers = repo.customersForDriver(driverId);
        final routes = repo.deliveryRoutesForDriver(driverId);
        final hasUnassigned = repo.driverUnassignedCustomerCount(driverId) > 0;
        final instantOrders = repo.driverInstantOrders(driverId: driverId);
        final appOrders = repo
            .driverAppAcceptedOrders(driverId: driverId)
            .where((order) => _orderMatchesRoute(order, repo))
            .toList();
        final driverAlerts =
            notifications.unreadCountForDriver(driverId: driverId);
        final strings = context.l10n;

        return Scaffold(
          backgroundColor: DriverColors.contentBg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DeliveriesToolbar(
                dispatchCount: instantOrders.length,
                shopName: assignedShop?.name,
                unreadAlerts: driverAlerts,
                onNotifications: () => _showNotifications(context, driverId),
              ),
              Expanded(
                child: ListView(
                  children: [
                    DriverRouteFilter(
                      routes: routes,
                      selected: _routeFilter,
                      showUnassigned: hasUnassigned,
                      allCustomerCount: assignedCustomers.length,
                      unassignedCustomerCount: repo
                          .driverUnassignedCustomerCount(driverId),
                      customerCountForRoute: (routeId) =>
                          repo.driverCustomerCountOnRoute(driverId, routeId),
                      onSelected: (routeId) =>
                          setState(() => _routeFilter = routeId),
                    ),
                    if (instantOrders.isNotEmpty) ...[
                      DriverSectionTitle(
                        title:
                            '${strings.instantDelivery} (${instantOrders.length})',
                        trailing: Text(
                          strings.collectCash,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                      ...instantOrders.map((o) {
                        final customer = repo.customerById(o.customerId);
                        final estimate = customer == null
                            ? 0.0
                            : repo.estimateDispatchTotal(customer, o.lineItems);
                        return DriverInstantDeliveryCard(
                          order: o,
                          repo: repo,
                          driverId: driverId,
                          estimatedTotal: estimate,
                        );
                      }),
                    ],
                    if (appOrders.isNotEmpty) ...[
                      DriverSectionTitle(
                        title: '${strings.deliveries} (${appOrders.length})',
                        trailing: Text(
                          strings.adminConfirmed,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                      ...appOrders.map(
                        (o) => DriverAcceptedOrderCard(
                          order: o,
                          repo: repo,
                          driverId: driverId,
                        ),
                      ),
                    ],
                    if (instantOrders.isEmpty &&
                        appOrders.isEmpty &&
                        AppConfig.useInstantDispatchMock)
                      _EmptyCard(
                        icon: Icons.bolt_rounded,
                        message: strings.noInstantJobs,
                      ),
                    DriverSectionTitle(title: strings.completedToday),
                    if (deliveries.isEmpty)
                      _EmptyCard(
                        icon: Icons.local_shipping_outlined,
                        message: strings.savedDeliveriesHere,
                      )
                    else
                      ...deliveries.map((d) {
                        final c = repo.customerById(d.customerId);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: ListTile(
                            onTap: c != null
                                ? () =>
                                      context.push('/driver/customers/${c.id}')
                                : null,
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: DriverColors.cardBorder,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: DriverColors.success.withValues(
                                alpha: 0.12,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: DriverColors.success,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              c?.driverDisplayName(strings) ??
                                  strings.customers,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(strings.deliveryItemsSummary(d)),
                            trailing: Text(
                              d.date.timeLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: DriverColors.labelGrey,
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotifications(BuildContext context, String? driverId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _DriverNotificationsSheet(driverId: driverId),
    );
  }

  bool _orderMatchesRoute(CustomerOrder order, WaterPlantRepository repo) {
    if (order.isPhoneDispatch) return true;
    final customer = repo.customerById(order.customerId);
    if (customer == null) return _routeFilter == null;
    return _matchesRoute(customer);
  }

  bool _deliveryMatchesRoute(Delivery delivery, WaterPlantRepository repo) {
    final customer = repo.customerById(delivery.customerId);
    if (customer == null) return _routeFilter == null;
    return _matchesRoute(customer);
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

class _DeliveriesToolbar extends StatelessWidget {
  const _DeliveriesToolbar({
    required this.dispatchCount,
    required this.shopName,
    required this.unreadAlerts,
    required this.onNotifications,
  });

  final int dispatchCount;
  final String? shopName;
  final int unreadAlerts;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DriverColors.headerStart,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 10,
        12,
        14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.deliveries,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dispatchCount > 0
                      ? context.l10n.instantOrdersWaiting(dispatchCount)
                      : shopName ?? context.l10n.customers,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: unreadAlerts > 0,
              label: Text('$unreadAlerts'),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverNotificationsSheet extends StatelessWidget {
  const _DriverNotificationsSheet({required this.driverId});

  final String? driverId;

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationRepository>(
      builder: (context, notificationRepo, _) {
        final items = notificationRepo.forDriver(driverId: driverId);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.78,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DriverColors.cardBorder,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.notifications,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: DriverColors.titleNavy,
                          ),
                        ),
                      ),
                      if (items.any((n) => !n.read))
                        TextButton(
                          onPressed: notificationRepo.markAllReadForDriver,
                          child: Text(
                            context.l10n.markAllRead,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: DriverColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        context.l10n.noDriverNotifications,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: DriverColors.labelGrey,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _DriverNotificationTile(
                            notification: item,
                            onTap: () async {
                              notificationRepo.markRead(item.id);
                              final orderId = item.orderId;
                              if (orderId == null || orderId.isEmpty) return;
                              final repo = context.read<WaterPlantRepository>();
                              await repo.hydrateDriverOrderById(
                                orderId,
                                driverId: driverId,
                              );
                              await repo.loadCustomersForCurrentAdminFromFirestore(
                                force: true,
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DriverNotificationTile extends StatelessWidget {
  const _DriverNotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: notification.read ? Colors.white : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: notification.read
                  ? DriverColors.cardBorder
                  : const Color(0xFFEA580C).withValues(alpha: 0.45),
            ),
          ),
          leading: Icon(
            notification.type == AppNotificationType.orderAccepted
                ? Icons.assignment_turned_in_rounded
                : Icons.local_shipping_rounded,
            color: notification.read
                ? DriverColors.accent
                : const Color(0xFFEA580C),
          ),
          title: Text(
            notification.title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: DriverColors.titleNavy,
            ),
          ),
          subtitle: Text(
            '${notification.body}\n${notification.createdAt.timeLabel}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: DriverColors.labelGrey,
              height: 1.35,
            ),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: DriverColors.cardDecoration,
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: DriverColors.accent.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: DriverColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}
