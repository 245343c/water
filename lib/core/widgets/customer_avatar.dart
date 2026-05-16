import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({
    super.key,
    required this.initials,
    this.size = 48,
    this.colorIndex = 0,
  });

  final String initials;
  final double size;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final i = colorIndex % AppColors.avatarColors.length;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.avatarColors[i],
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.avatarTextColors[i],
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}
