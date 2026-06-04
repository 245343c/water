import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

void showDriverDeliverySuccessSheet(
  BuildContext context, {
  required String customerName,
  required Delivery delivery,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DriverColors.accent.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: DriverColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 44, color: DriverColors.success),
          ),
          const SizedBox(height: 16),
          Text(
            delivery.isEmptyReturnOnly ? 'Empty return saved' : 'Delivery saved',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${delivery.itemsSummary} for $customerName',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: DriverColors.labelGrey),
          ),
          if (delivery.totalEmptyReturned > 0 &&
              !delivery.isEmptyReturnOnly) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.recycling_rounded, size: 16, color: DriverColors.accent),
                const SizedBox(width: 6),
                Text(
                  '${delivery.totalEmptyReturned} empty can${delivery.totalEmptyReturned == 1 ? '' : 's'} collected',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DriverColors.accent,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DriverColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: DriverColors.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Customer & admin notified. Bill updated for both.',
                    style: GoogleFonts.poppins(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: DriverColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Continue', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}
