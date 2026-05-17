import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/theme/app_text_styles.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_card.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';

class DeliveryListTile extends StatelessWidget {
  const DeliveryListTile({
    super.key,
    required this.customerName,
    required this.delivery,
    this.onTap,
    this.compact = false,
  });

  final String customerName;
  final Delivery delivery;
  final VoidCallback? onTap;
  final bool compact;

  String _time(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.infoBannerBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customerName,
                  style: AppTextStyles.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!compact || delivery.itemsSummary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    delivery.itemsSummary,
                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (compact)
            Text(_time(delivery.date), style: AppTextStyles.caption.copyWith(fontSize: 12))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyUtils.format(delivery.totalAmount),
                  style: AppTextStyles.statValue.copyWith(fontSize: 14, color: AppColors.primary),
                ),
                Text(_time(delivery.date), style: AppTextStyles.caption),
              ],
            ),
        ],
      ),
    );
  }
}
