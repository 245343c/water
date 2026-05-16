import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/theme/app_text_styles.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_card.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.accentColor,
  });

  final String label;
  final String? subtitle;
  final int value;
  final ValueChanged<int> onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    return PremiumCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.customerName.copyWith(fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          _Btn(icon: Icons.remove, onTap: value > 0 ? () => onChanged(value - 1) : null, accent: accent),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.statValue.copyWith(fontSize: 20),
            ),
          ),
          _Btn(
            icon: Icons.add,
            filled: true,
            accent: accent,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(value + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap, required this.accent, this.filled = false});
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? accent : accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: filled ? Colors.white : accent, size: 20),
        ),
      ),
    );
  }
}
