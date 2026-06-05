import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Driver home: accepted customer requests + today's route + completed.
class DriverRouteScreen extends StatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  String? _routeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = context.read<WaterPlantRepository>();
      await repo.loadDeliveryRoutesForCurrentAdmin();
      await repo.loadCustomersForCurrentAdminFromFirestore(force: true);
      if (AppConfig.useInstantDispatchMock) {
        repo.restoreMockInstantDispatchForDriver();
      }
    });
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
        final acceptedOrders = [...instantOrders, ...appOrders];
        final acceptedCustomerIds = acceptedOrders
            .map((order) => order.customerId)
            .toSet();
        final route = repo
            .todaysRouteCustomersForDriver(driverId)
            .where(_matchesRoute)
            .toList();
        final pendingRoute = route
            .where(
              (c) =>
                  !repo.hasDeliveryToday(c.id) &&
                  !acceptedCustomerIds.contains(c.id),
            )
            .toList();
        final driverAlerts = notifications.unreadCountForDriver();

        return Scaffold(
          backgroundColor: DriverColors.contentBg,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DeliveriesToolbar(
                dispatchCount: instantOrders.length,
                shopName: assignedShop?.name,
                unreadAlerts: driverAlerts,
                onNotifications: () => _showNotifications(context),
              ),
                Expanded(
                  child: ListView(
                    children: [
                      DriverRouteFilter(
                        routes: routes,
                        selected: _routeFilter,
                        showUnassigned: hasUnassigned,
                        allCustomerCount: assignedCustomers.length,
                        unassignedCustomerCount:
                            repo.driverUnassignedCustomerCount(driverId),
                        customerCountForRoute: (routeId) =>
                            repo.driverCustomerCountOnRoute(driverId, routeId),
                        onSelected: (routeId) =>
                            setState(() => _routeFilter = routeId),
                      ),
                      if (instantOrders.isNotEmpty) ...[
                        DriverSectionTitle(
                          title: 'Instant delivery (${instantOrders.length})',
                          trailing: Text(
                            'Collect payment',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        ...instantOrders.map((o) {
                          final customer =
                              repo.customerById(o.customerId);
                          final estimate = customer == null
                              ? 0.0
                              : repo.estimateDispatchTotal(
                                  customer,
                                  o.lineItems,
                                );
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
                          title: 'App requests (${appOrders.length})',
                          trailing: Text(
                            'Admin confirmed',
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
                        const _EmptyCard(
                          icon: Icons.bolt_rounded,
                          message:
                              'No instant jobs right now. Admin will add phone orders here.',
                        ),
                      DriverSectionTitle(
                        title: 'Regular customers (${pendingRoute.length} left)',
                        trailing: TextButton(
                          onPressed: () =>
                              context.go(AppRoutes.driverCustomers),
                          child: Text(
                            'All customers',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DriverColors.accent,
                            ),
                          ),
                        ),
                      ),
                      if (pendingRoute.isEmpty)
                        _EmptyCard(
                          icon: Icons.check_circle_outline_rounded,
                          message: 'All route stops done for today',
                        )
                      else
                        ...pendingRoute.map((c) {
                          final order = repo.acceptedOrderForCustomer(
                            c.id,
                            driverId: driverId,
                          );
                          return DriverRouteStopCard(
                            customerName: c.name,
                            place: c.place,
                            initials: c.initials,
                            done: repo.hasDeliveryToday(c.id),
                            note: repo.routeNoteForCustomer(c.id),
                            hasAcceptedOrder: order != null,
                            onTap: () =>
                                context.push('/driver/customers/${c.id}'),
                          );
                        }),
                      const DriverSectionTitle(title: 'Completed today'),
                      if (deliveries.isEmpty)
                        _EmptyCard(
                          icon: Icons.local_shipping_outlined,
                          message: 'Saved deliveries appear here',
                        )
                      else
                        ...deliveries.map((d) {
                          final c = repo.customerById(d.customerId);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: ListTile(
                              onTap: c != null
                                  ? () => context.push(
                                      '/driver/customers/${c.id}',
                                    )
                                  : null,
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(
                                  color: DriverColors.cardBorder,
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: DriverColors.success
                                    .withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.check,
                                  color: DriverColors.success,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                c?.name ?? 'Customer',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(d.cansSummary),
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

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _DriverNotificationsSheet(),
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
                  'Deliveries',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dispatchCount > 0
                      ? '$dispatchCount dispatch(es) waiting'
                      : shopName ?? 'Your assigned customers',
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
              child: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverNotificationsSheet extends StatelessWidget {
  const _DriverNotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationRepository>(
      builder: (context, notificationRepo, _) {
        final items = notificationRepo.forDriver();
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
                          'Notifications',
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
                            'Mark all read',
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
                        'No driver notifications yet',
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
                            onTap: () => notificationRepo.markRead(item.id),
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
