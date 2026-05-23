import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/app_notification.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotificationRepository, WaterPlantRepository>(
      builder: (context, notifications, repo, _) {
        final items = notifications.forAdmin();

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: Column(
            children: [
              Container(
                decoration: CustomersColors.headerGradient,
                padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 8, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (items.isNotEmpty)
                      TextButton(
                        onPressed: notifications.markAllReadForAdmin,
                        child: Text(
                          'Read all',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'No notifications yet',
                          style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final n = items[i];
                          final customer = n.customerId != null
                              ? repo.customerById(n.customerId!)
                              : null;
                          return _NotificationTile(
                            notification: n,
                            customerName: customer?.name,
                            onTap: () => notifications.markRead(n.id),
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
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    this.customerName,
  });

  final AppNotification notification;
  final String? customerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.read;
    final style = _NotificationIconStyle.forType(notification.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: unread ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                width: unread ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                      if (customerName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          customerName!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        notification.createdAt.timeLabel,
                        style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationIconStyle {
  const _NotificationIconStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static _NotificationIconStyle forType(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.orderPlaced => const _NotificationIconStyle(
          icon: Icons.receipt_long_rounded,
          color: Color(0xFF2563EB),
        ),
      AppNotificationType.orderAccepted => const _NotificationIconStyle(
          icon: Icons.local_shipping_rounded,
          color: Color(0xFF0D9488),
        ),
      AppNotificationType.orderRejected => const _NotificationIconStyle(
          icon: Icons.cancel_rounded,
          color: Color(0xFFDC2626),
        ),
      AppNotificationType.deliveryRecorded => const _NotificationIconStyle(
          icon: Icons.inventory_2_rounded,
          color: Color(0xFF16A34A),
        ),
      AppNotificationType.paymentReceived => const _NotificationIconStyle(
          icon: Icons.payments_rounded,
          color: Color(0xFF7C3AED),
        ),
    };
  }
}
