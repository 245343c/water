import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_route_widgets.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Driver home: accepted customer requests + today's route + completed.
class DriverRouteScreen extends StatelessWidget {
  const DriverRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<WaterPlantRepository, NotificationRepository, AuthRepository>(
      builder: (context, repo, notifications, auth, _) {
        final driverId = auth.currentUser?.driverId;
        final assignedShop = repo.shopForDriver(driverId);
        final today = DateTime.now();
        final deliveries = repo.deliveriesOnDateForDriver(today, driverId);
        final cans = repo.cansDeliveredOnDateForDriver(today, driverId);
        final acceptedOrders = repo.driverAcceptedOrders(driverId: driverId);
        final route = repo.todaysRouteCustomersForDriver(driverId);
        final pendingRoute = route
            .where((c) => !repo.hasDeliveryToday(c.id))
            .toList();
        final driverAlerts = notifications.unreadCountForDriver();

        return Scaffold(
          backgroundColor: DriverColors.screenBg,
          body: DriverScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DriverHeader(
                  title: 'My route',
                  subtitle: acceptedOrders.isNotEmpty
                      ? '${acceptedOrders.length} confirmed order(s) to deliver'
                      : assignedShop == null
                          ? 'Driver is not linked to a water plant'
                          : '${assignedShop.name} customers only',
                ),
                Expanded(
                  child: ListView(
                    children: [
                      DriverHeroStats(
                        deliveriesToday: deliveries.length,
                        cansToday: cans,
                        pendingOrders: acceptedOrders.length,
                        pendingLabel: 'Tasks',
                      ),
                      if (driverAlerts > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: Material(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => context.go(AppRoutes.driverProfile),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.notifications_active_rounded,
                                        color: Color(0xFFEA580C)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '$driverAlerts new alert(s) — tap Profile to view',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (acceptedOrders.isNotEmpty) ...[
                        DriverSectionTitle(
                          title: 'Customer requests (${acceptedOrders.length})',
                          trailing: Text(
                            'Admin confirmed',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                        ...acceptedOrders.map(
                          (o) => DriverAcceptedOrderCard(order: o, repo: repo),
                        ),
                      ],
                      DriverSectionTitle(
                        title: "Today's stops (${pendingRoute.length} left)",
                        trailing: TextButton(
                          onPressed: () => context.go(AppRoutes.driverCustomers),
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
                            onTap: () => context.push('/driver/customers/${c.id}'),
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
                                  ? () => context.push('/driver/customers/${c.id}')
                                  : null,
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: DriverColors.cardBorder),
                              ),
                              leading: CircleAvatar(
                                backgroundColor: DriverColors.success.withValues(alpha: 0.12),
                                child: const Icon(Icons.check, color: DriverColors.success, size: 20),
                              ),
                              title: Text(
                                c?.name ?? 'Customer',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(d.cansSummary),
                              trailing: Text(
                                d.date.timeLabel,
                                style: GoogleFonts.poppins(fontSize: 11, color: DriverColors.labelGrey),
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
          ),
        );
      },
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
          Icon(icon, size: 40, color: DriverColors.accent.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: DriverColors.labelGrey),
          ),
        ],
      ),
    );
  }
}
