import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.isPaid});

  final String label;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final bg = isPaid ? AppColors.successLight : AppColors.warningLight;
    final fg = isPaid ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
