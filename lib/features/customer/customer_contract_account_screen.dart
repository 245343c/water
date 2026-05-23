import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_info_bar.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_shop_billing.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_detail_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Monthly account — billing per linked shop.
class CustomerContractAccountScreen extends StatelessWidget {
  const CustomerContractAccountScreen({
    super.key,
    this.focusShopId,
    this.showBackButton = false,
  });

  final String? focusShopId;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final userId = auth.currentUser?.id;
    var billings = userId != null
        ? repo.shopBillingsForAppUser(userId)
        : <CustomerShopBilling>[];
    if (focusShopId != null) {
      billings = billings.where((b) => b.shop.id == focusShopId).toList();
    }
    final totalPending = focusShopId == null
        ? (userId != null ? repo.totalPendingForAppUser(userId) : 0.0)
        : billings.fold<double>(
            0,
            (sum, b) => sum + repo.customerBalance(b.customer.id),
          );

    return CustomerScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountTopHeader(
            shopCount: billings.length,
            title: focusShopId == null ? 'Account' : 'Plant details',
            subtitle: focusShopId == null
                ? null
                : billings.isEmpty
                ? 'Monthly account'
                : billings.first.shop.name,
            onBack: showBackButton ? () => context.pop() : null,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                bottom: customerBottomInset(context, extra: 16),
              ),
              children: [
                if (billings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: CustomerEmptyState(
                      icon: Icons.link_off_rounded,
                      title: 'Billing not linked yet',
                      message:
                          'Your shop must add you as a monthly customer with this phone number. Then sign in again to see bills from each shop.',
                    ),
                  )
                else ...[
                  if (billings.length > 1)
                    _AllShopsSummary(
                      billings: billings,
                      totalPending: totalPending,
                    ),
                  ...billings.map(
                    (b) => _ShopBillingSection(
                      billing: b,
                      colorIndex: billings.indexOf(b),
                      compactDetails: focusShopId != null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTopHeader extends StatelessWidget {
  const _AccountTopHeader({
    required this.shopCount,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final int shopCount;
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF4C1D95), Color(0xFF6D28D9)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            shopCount > 1
                ? '$shopCount shops · Monthly billing'
                : 'Monthly billing with your shop',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllShopsSummary extends StatelessWidget {
  const _AllShopsSummary({required this.billings, required this.totalPending});

  final List<CustomerShopBilling> billings;
  final double totalPending;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final repo = context.watch<WaterPlantRepository>();
    var monthTotal = 0.0;
    for (final b in billings) {
      monthTotal += repo
          .monthlyStatsForCustomer(b.customer.id, month)
          .totalAmount;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: CustomerColors.cardDecoration,
        child: Row(
          children: [
            _SummaryChip(
              value: '${billings.length}',
              label: 'Shops',
              icon: Icons.storefront_rounded,
              color: CustomerColors.accent,
            ),
            _SummaryChip(
              value: CurrencyUtils.format(monthTotal),
              label: 'This month',
              icon: Icons.receipt_long_rounded,
              color: CustomerColors.contractPurple,
            ),
            _SummaryChip(
              value: CurrencyUtils.format(
                totalPending.clamp(0.0, double.infinity),
              ),
              label: 'Due',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFEA580C),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: CustomerColors.titleNavy,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: CustomerColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopBillingSection extends StatelessWidget {
  const _ShopBillingSection({
    required this.billing,
    required this.colorIndex,
    required this.compactDetails,
  });

  final CustomerShopBilling billing;
  final int colorIndex;
  final bool compactDetails;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WaterPlantRepository>();
    final crm = billing.customer;
    final shop = billing.shop;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final monthly = repo.monthlyStatsForCustomer(crm.id, currentMonth);
    final pending = repo.customerBalance(crm.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShopBillingHeader(shop: shop, pending: pending),
          if (!compactDetails) ...[
            _ShopMonthlyBillCard(
              shop: shop,
              customer: crm,
              stats: monthly,
              pending: pending,
              onViewBill: () => context.push(
                '${AppRoutes.customerMonthlyBill}?customerId=${crm.id}'
                '&shopId=${shop.id}&year=${now.year}&month=${now.month}',
              ),
            ),
            CustomerInfoBar(customer: crm, colorIndex: colorIndex),
          ],
          CustomerPendingCard(
            totalPending: pending,
            advanceCredit: repo.customerAdvanceCredit(crm.id),
            previousPending: repo.previousBalanceForMonth(crm.id, currentMonth),
            monthStats: monthly,
          ),
          CustomerMonthlyOverviewSection(
            statsForMonth: (m) => repo.monthlyStatsForCustomer(crm.id, m),
            onMonthTap: (m) => context.push(
              '${AppRoutes.customerMonthDetail}?customerId=${crm.id}'
              '&shopId=${shop.id}&year=${m.year}&month=${m.month}',
            ),
            year: now.year,
            initialMonth: now.month,
            emptyHint: 'No deliveries at ${shop.name} this month',
            footerHint: 'Tap a month · View bill matches admin',
          ),
          if (shop.isVisibleToCustomers)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: CustomerPrimaryButton(
                label: 'Request water from ${shop.name}',
                icon: Icons.shopping_bag_outlined,
                onPressed: () => context.push('/customer/shop/${shop.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopBillingHeader extends StatelessWidget {
  const _ShopBillingHeader({required this.shop, required this.pending});

  final Shop shop;
  final double pending;

  @override
  Widget build(BuildContext context) {
    final letter = shop.name.isNotEmpty ? shop.name[0].toUpperCase() : '?';
    final isDue = pending > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: CustomerColors.accent.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CustomerColors.accent,
                  CustomerColors.accent.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerColors.titleNavy,
                  ),
                ),
                if (shop.tagline.isNotEmpty)
                  Text(
                    shop.tagline,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: CustomerColors.labelGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: CustomerColors.labelGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop.address,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: CustomerColors.labelGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDue ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDue
                    ? const Color(0xFFFDBA74)
                    : const Color(0xFF86EFAC),
              ),
            ),
            child: Text(
              isDue ? 'Due' : 'Clear',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDue
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopMonthlyBillCard extends StatelessWidget {
  const _ShopMonthlyBillCard({
    required this.shop,
    required this.customer,
    required this.stats,
    required this.pending,
    required this.onViewBill,
  });

  final Shop shop;
  final Customer customer;
  final MonthlyStats stats;
  final double pending;
  final VoidCallback onViewBill;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = '${_months[now.month - 1]} ${now.year}';
    final isPaid = pending <= 0 && stats.totalAmount > 0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  monthLabel,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid
                        ? 'PAID'
                        : stats.totalAmount > 0
                        ? 'DUE'
                        : 'NO ACTIVITY',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              CurrencyUtils.format(stats.totalAmount),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Bill amount · ${stats.normalCans + stats.coolCans} cans this month',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onViewBill,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text(
                'View bill',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReadOnlyBanner extends StatelessWidget {
  const ReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: CustomerColors.contractPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CustomerColors.contractPurple.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 20,
              color: CustomerColors.contractPurple,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'View only — each shop records deliveries & payments separately',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CustomerColors.titleNavy,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
