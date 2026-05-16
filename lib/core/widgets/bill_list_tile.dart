import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/theme/app_text_styles.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_avatar.dart';
import 'package:sri_sai_ro_water/core/widgets/mockup_widgets.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_card.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';

class BillListTile extends StatelessWidget {
  const BillListTile({
    super.key,
    required this.customer,
    required this.stats,
    required this.colorIndex,
    required this.onTap,
  });

  final Customer customer;
  final MonthlyStats stats;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      child: Row(
        children: [
          CustomerAvatar(initials: customer.initials, colorIndex: colorIndex),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: AppTextStyles.customerName),
                const SizedBox(height: 4),
                Text('${stats.normalCans} Normal · ${stats.coolCans} Cool', style: AppTextStyles.bodySecondary),
                const SizedBox(height: 6),
                MockupStatusBadge(label: stats.statusLabel, isPaid: stats.isPaid),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(CurrencyUtils.format(stats.totalAmount), style: AppTextStyles.statValue.copyWith(color: AppColors.primary)),
              if (stats.balance > 0)
                Text('Due ${CurrencyUtils.format(stats.balance)}', style: AppTextStyles.caption.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
