import 'package:flutter/material.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/theme/app_text_styles.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_avatar.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_card.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';

class CustomerListTile extends StatelessWidget {
  const CustomerListTile({
    super.key,
    required this.customer,
    required this.colorIndex,
    required this.balance,
    required this.onTap,
  });

  final Customer customer;
  final int colorIndex;
  final double balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDebt = balance > 0;
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CustomerAvatar(initials: customer.initials, colorIndex: colorIndex),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: AppTextStyles.customerName),
                const SizedBox(height: 2),
                Text(customer.phone, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Balance',
                style: AppTextStyles.caption.copyWith(
                  color: hasDebt ? AppColors.danger : AppColors.textSecondary,
                ),
              ),
              Text(
                CurrencyUtils.format(balance),
                style: AppTextStyles.statValue.copyWith(
                  fontSize: 15,
                  color: hasDebt ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
        ],
      ),
    );
  }
}
