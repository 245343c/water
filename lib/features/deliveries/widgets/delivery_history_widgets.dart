import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/monthly_metrics_list.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class DeliveryHistoryColors {
  static const Color titleNavy = Color(0xFF1E3A8A);
  static const Color valueNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color screenBg = Color(0xFFF3F4F6);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color whatsapp = Color(0xFF25D366);
}

class DeliveryHistoryHeader extends StatelessWidget {
  const DeliveryHistoryHeader({
    super.key,
    required this.onBack,
    this.onFilter,
  });

  final VoidCallback onBack;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 4, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Delivery History',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white, size: 22),
            onPressed: onFilter,
          ),
        ],
      ),
    );
  }
}

class DeliveryHistoryCustomerBar extends StatelessWidget {
  const DeliveryHistoryCustomerBar({
    super.key,
    required this.customer,
    required this.colorIndex,
  });

  final Customer customer;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final bg = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Container(
      color: DeliveryHistoryColors.screenBg,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: bg,
            child: Text(
              customer.initials,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DeliveryHistoryColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: DeliveryHistoryColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: DeliveryHistoryColors.whatsapp.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.chat, color: DeliveryHistoryColors.whatsapp, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryHistoryMonthNav extends StatelessWidget {
  const DeliveryHistoryMonthNav({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DeliveryHistoryColors.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: DeliveryHistoryColors.labelGrey),
              onPressed: onPrev,
            ),
            Expanded(
              child: Text(
                month.monthYear,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: DeliveryHistoryColors.valueNavy,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: DeliveryHistoryColors.labelGrey),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryHistoryListCard extends StatelessWidget {
  const DeliveryHistoryListCard({
    super.key,
    required this.deliveries,
  });

  final List<Delivery> deliveries;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DeliveryHistoryColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: deliveries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No deliveries this month',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: DeliveryHistoryColors.labelGrey,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: deliveries.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                thickness: 1,
                color: DeliveryHistoryColors.divider,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (_, i) => _HistoryRow(delivery: deliveries[i]),
            ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              delivery.date.fullDate,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DeliveryHistoryColors.valueNavy,
              ),
            ),
          ),
          Expanded(
            child: Text(
              delivery.itemsSummary,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: DeliveryHistoryColors.valueNavy,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            CurrencyUtils.format(delivery.totalAmount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DeliveryHistoryColors.valueNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryHistoryMonthTotalCard extends StatelessWidget {
  const DeliveryHistoryMonthTotalCard({
    super.key,
    required this.stats,
  });

  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DeliveryHistoryColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month Total',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DeliveryHistoryColors.titleNavy,
              ),
            ),
            const SizedBox(height: 10),
            MonthlyMetricsList(
              stats: stats,
              labelColor: DeliveryHistoryColors.labelGrey,
              valueColor: DeliveryHistoryColors.statBlue,
              titleNavy: DeliveryHistoryColors.titleNavy,
              dividerColor: DeliveryHistoryColors.divider,
              showTotalAndStatus: false,
            ),
            Divider(height: 1, color: DeliveryHistoryColors.divider),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DeliveryHistoryColors.labelGrey,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyUtils.format(stats.totalAmount),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: DeliveryHistoryColors.statGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeliveryHistoryScaffold extends StatelessWidget {
  const DeliveryHistoryScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: child,
    );
  }
}
