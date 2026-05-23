import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/app_notification.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final user = auth.currentUser;
    final repo = context.watch<WaterPlantRepository>();
    final driver = user?.driverId != null ? repo.driverById(user!.driverId) : null;
    final driverId = user?.driverId;
    final assignedShop = repo.shopForDriver(driverId);
    final today = DateTime.now();
    final deliveries = repo.deliveriesOnDateForDriver(today, driverId);
    final cans = repo.cansDeliveredOnDateForDriver(today, driverId);

    final notifications = context.watch<NotificationRepository>();
    final alerts = notifications.forDriver().take(8).toList();

    return Scaffold(
      backgroundColor: DriverColors.screenBg,
      body: DriverScaffold(
        child: Column(
          children: [
            DriverHeader(
              title: 'Profile',
              subtitle: alerts.any((a) => !a.read)
                  ? '${notifications.unreadCountForDriver()} unread alert(s)'
                  : 'Driver account',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: DriverColors.cardDecoration,
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: DriverColors.headerGradient.gradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.ownerName ?? 'Driver',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: DriverColors.titleNavy,
                                ),
                              ),
                              Text(
                                'Delivery staff',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: DriverColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.labelGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Today',
                          value: '${deliveries.length}',
                          sub: 'trips',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniStat(
                          label: 'Cans',
                          value: '$cans',
                          sub: 'delivered',
                        ),
                      ),
                    ],
                  ),
                  if (alerts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alerts',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: notifications.markAllReadForDriver,
                          child: Text(
                            'Mark all read',
                            style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...alerts.map(
                      (n) => _DriverAlertTile(
                        notification: n,
                        onTap: () => notifications.markRead(n.id),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: DriverColors.cardDecoration,
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.phone_outlined, text: driver?.phone ?? user?.phone ?? ''),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.store_rounded,
                          text: assignedShop?.name ?? 'No plant assigned',
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.group_outlined,
                          text:
                              '${repo.customersForDriver(driverId).length} assigned customers',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () {
                        auth.logout();
                        context.go(AppRoutes.login);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Text(
                              'Sign out',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DriverColors.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: DriverColors.labelGrey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: DriverColors.accent,
            ),
          ),
          Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: DriverColors.labelGrey)),
        ],
      ),
    );
  }
}

class _DriverAlertTile extends StatelessWidget {
  const _DriverAlertTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: notification.read ? DriverColors.cardBorder : const Color(0xFFEA580C),
            ),
          ),
          leading: Icon(
            notification.type == AppNotificationType.orderAccepted
                ? Icons.assignment_turned_in_rounded
                : Icons.local_shipping_rounded,
            color: DriverColors.accent,
          ),
          title: Text(
            notification.title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            '${notification.body}\n${notification.createdAt.timeLabel}',
            style: GoogleFonts.poppins(fontSize: 11, color: DriverColors.labelGrey),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: DriverColors.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 13, color: DriverColors.titleNavy),
          ),
        ),
      ],
    );
  }
}
