import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/services/delivery_recording_service.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// Driver field stepper — used on delivery and empty-return flows.
class DriverCanStepperRow extends StatelessWidget {
  const DriverCanStepperRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
    this.maxValue,
    this.compact = false,
  });

  final String label;
  final String? subtitle;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;
  final int? maxValue;
  final bool compact;

  bool get _atMax =>
      maxValue != null && value >= maxValue!;

  @override
  Widget build(BuildContext context) {
    final pad = compact ? 10.0 : 12.0;
    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: DriverColors.labelGrey,
                    ),
                  ),
              ],
            ),
          ),
          _DriverRoundBtn(
            icon: Icons.remove,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: GoogleFonts.poppins(
                fontSize: compact ? 22 : 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          _DriverRoundBtn(
            icon: Icons.add,
            filled: true,
            color: color,
            onTap: _atMax
                ? null
                : value < DeliveryRecordingService.maxCansPerDelivery
                    ? () => onChanged(value + 1)
                    : null,
          ),
        ],
      ),
    );
  }
}

class _DriverRoundBtn extends StatelessWidget {
  const _DriverRoundBtn({
    required this.icon,
    this.onTap,
    this.filled = false,
    this.color = DriverColors.accent,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: filled ? Colors.white : color, size: 22),
        ),
      ),
    );
  }
}
