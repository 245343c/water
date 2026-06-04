import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Admin-confirmed customer request the driver must deliver.
class DriverAcceptedOrderCard extends StatelessWidget {
  const DriverAcceptedOrderCard({
    super.key,
    required this.order,
    required this.repo,
    required this.driverId,
  });

  final CustomerOrder order;
  final WaterPlantRepository repo;
  final String? driverId;

  @override
  Widget build(BuildContext context) {
    final customer = repo.customerById(order.customerId);
    final walkIn = order.walkInContact;
    final displayName = walkIn?.name ?? customer?.name ?? 'Walk-in';
    final displayPhone = walkIn?.phone ?? customer?.phone ?? '';
    final displayAddress = walkIn?.address ?? customer?.address ?? '';
    final displayPlace = walkIn?.place ?? customer?.place ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push(
            '/driver/customers/${order.customerId}?orderId=${order.id}',
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: order.isPhoneDispatch
                    ? const Color(0xFF7C3AED).withValues(alpha: 0.45)
                    : const Color(0xFFFDBA74).withValues(alpha: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.titleNavy,
                        ),
                      ),
                    ),
                    _RequestBadge(
                      label: order.isPhoneDispatch ? 'Walk-in' : 'Dispatch',
                      icon: order.isPhoneDispatch
                          ? Icons.call_rounded
                          : Icons.verified_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  displayPhone,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: DriverColors.labelGrey,
                  ),
                ),
                Text(
                  displayPlace.isNotEmpty
                      ? '$displayPlace · $displayAddress'
                      : displayAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: DriverColors.titleNavy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.itemsSummary,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DriverColors.accent,
                  ),
                ),
                Text(
                  'Collect payment at door',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFFEA580C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (order.customerNote != null &&
                    order.customerNote!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    order.customerNote!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: DriverColors.labelGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DriverPrimaryButton(
                  label: 'Deliver now',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.push(
                    '/driver/customers/${order.customerId}?orderId=${order.id}',
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

class _RequestBadge extends StatelessWidget {
  const _RequestBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEA580C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CanChip extends StatelessWidget {
  const _CanChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DriverRouteStopCard extends StatelessWidget {
  const DriverRouteStopCard({
    super.key,
    required this.customerName,
    required this.place,
    required this.initials,
    required this.done,
    required this.note,
    required this.onTap,
    this.hasAcceptedOrder = false,
  });

  final String customerName;
  final String place;
  final String initials;
  final bool done;
  final String? note;
  final bool hasAcceptedOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: DriverColors.cardDecoration.copyWith(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: DriverColors.accent.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        initials,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: DriverColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            place,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: DriverColors.labelGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasAcceptedOrder)
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFFEA580C),
                        size: 20,
                      ),
                    if (done)
                      const Icon(
                        Icons.check_circle,
                        color: DriverColors.success,
                        size: 22,
                      ),
                  ],
                ),
                if (note != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    note!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: DriverColors.accent,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                DriverPrimaryButton(
                  label: done ? 'View customer' : 'Record delivery',
                  onPressed: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  return date.dayMonth;
}
