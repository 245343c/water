import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Admin-confirmed customer order — driver must deliver.
class DriverAcceptedOrderCard extends StatelessWidget {
  const DriverAcceptedOrderCard({
    super.key,
    required this.order,
    required this.repo,
  });

  final CustomerOrder order;
  final WaterPlantRepository repo;

  @override
  Widget build(BuildContext context) {
    final customer = repo.customerById(order.customerId);
    if (customer == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/driver/customers/${customer.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFF7ED),
                  Colors.white,
                ],
              ),
              border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Admin confirmed',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.local_shipping_rounded, color: Color(0xFFEA580C), size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  customer.name,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: DriverColors.titleNavy,
                  ),
                ),
                Text(
                  customer.place,
                  style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.labelGrey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (order.normalQty > 0) _CanChip(label: '${order.normalQty} Normal', color: const Color(0xFF2563EB)),
                    if (order.coolQty > 0) _CanChip(label: '${order.coolQty} Cool', color: DriverColors.accent),
                  ],
                ),
                if (order.customerNote != null && order.customerNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '“${order.customerNote}”',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: DriverColors.titleNavy,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Ask at door — enter actual cans delivered',
                  style: GoogleFonts.poppins(fontSize: 11, color: DriverColors.labelGrey),
                ),
                const SizedBox(height: 10),
                DriverPrimaryButton(
                  label: 'Open & record delivery',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.push('/driver/customers/${customer.id}'),
                ),
              ],
            ),
          ),
        ),
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
                      backgroundColor: DriverColors.accent.withValues(alpha: 0.15),
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
                            style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.labelGrey),
                          ),
                        ],
                      ),
                    ),
                    if (hasAcceptedOrder)
                      const Icon(Icons.notifications_active_rounded, color: Color(0xFFEA580C), size: 20),
                    if (done)
                      const Icon(Icons.check_circle, color: DriverColors.success, size: 22),
                  ],
                ),
                if (note != null) ...[
                  const SizedBox(height: 8),
                  Text(note!, style: GoogleFonts.poppins(fontSize: 11, color: DriverColors.accent)),
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
