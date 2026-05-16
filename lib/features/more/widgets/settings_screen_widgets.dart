import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AddEditCustomerColors.labelGrey,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.4,
                color: AddEditCustomerColors.labelGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SettingsPricesPreviewCard extends StatelessWidget {
  const SettingsPricesPreviewCard({
    super.key,
    required this.normalPrice,
    required this.coolPrice,
  });

  final double normalPrice;
  final double coolPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current rates preview',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AddEditCustomerColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Normal ${CurrencyUtils.format(normalPrice)} · Cool ${CurrencyUtils.format(coolPrice)}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'New deliveries use these prices. Existing deliveries keep their original rates.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.4,
                    color: AddEditCustomerColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
