import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';

abstract final class AppDecorations {
  static const double radius = 14;
  static const double radiusLg = 20;

  static BoxDecoration get card => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get statCell => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      );

  static BoxDecoration get infoBanner => BoxDecoration(
        color: AppColors.infoBannerBg,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: AppColors.infoBannerBorder),
      );

  static BoxDecoration get successScreen => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECFDF5), Color(0xFFF5F7FA)],
        ),
      );

  static BoxDecoration iconCircle(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      );
}
