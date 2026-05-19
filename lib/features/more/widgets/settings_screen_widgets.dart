import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AddEditCustomerColors.labelGrey,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.35,
                color: AddEditCustomerColors.labelGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single-line home delivery toggle for settings.
class SettingsHomeDeliverySwitch extends StatelessWidget {
  const SettingsHomeDeliverySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.delivery_dining_rounded,
                size: 22,
                color: value ? const Color(0xFF16A34A) : AddEditCustomerColors.labelGrey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Home delivery',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AddEditCustomerColors.titleNavy,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: const Color(0xFF16A34A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
