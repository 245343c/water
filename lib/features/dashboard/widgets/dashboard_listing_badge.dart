import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// Shows whether this shop is visible to customers in the app.
class DashboardListingBadge extends StatelessWidget {
  const DashboardListingBadge({
    super.key,
    required this.homeDeliveryAvailable,
  });

  final bool homeDeliveryAvailable;

  @override
  Widget build(BuildContext context) {
    final visible = homeDeliveryAvailable;
    final color = visible ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final bg = visible ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED);
    final icon = visible ? Icons.visibility_rounded : Icons.visibility_off_rounded;
    final title = visible ? 'Visible to customers' : 'Hidden from customer app';
    final subtitle = visible
        ? 'Home delivery ON · Customers can find your shop'
        : 'Pickup only · Turn on home delivery in Settings to list';

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/settings'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
