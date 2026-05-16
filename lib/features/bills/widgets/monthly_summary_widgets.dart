import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class MonthlySummaryColors {
  static const Color titleNavy = Color(0xFF1E3A8A);
  static const Color valueNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color canCardBg = Color(0xFFEFF6FF);
  static const Color canCardBorder = Color(0xFFBFDBFE);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color totalGreen = Color(0xFF16A34A);
  static const Color totalGreenBg = Color(0xFFECFDF5);
  static const Color statusOrange = Color(0xFFEA580C);
  static const Color balanceRed = Color(0xFFDC2626);
  static const Color paymentCardBg = Color(0xFFFFF7ED);
  static const Color infoBannerBg = Color(0xFFEFF6FF);
  static const Color primaryBtn = Color(0xFF1A73E8);
}

class MonthlySummaryHeader extends StatelessWidget {
  const MonthlySummaryHeader({super.key, required this.onBack});

  final VoidCallback onBack;

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
              'Monthly Summary',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class MonthlySummaryCustomerHeader extends StatelessWidget {
  const MonthlySummaryCustomerHeader({
    super.key,
    required this.customer,
    required this.month,
    required this.colorIndex,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final Customer customer;
  final DateTime month;
  final int colorIndex;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final bg = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: bg,
            child: Text(
              customer.initials,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: MonthlySummaryColors.valueNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: onPrevMonth,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.chevron_left, size: 20, color: MonthlySummaryColors.labelGrey),
                      ),
                    ),
                    Text(
                      month.monthYear,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: MonthlySummaryColors.labelGrey,
                      ),
                    ),
                    InkWell(
                      onTap: onNextMonth,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.chevron_right, size: 20, color: MonthlySummaryColors.labelGrey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlySummaryCanCards extends StatelessWidget {
  const MonthlySummaryCanCards({
    super.key,
    required this.normalCans,
    required this.coolCans,
  });

  final int normalCans;
  final int coolCans;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _CanCard(label: 'Normal Cans', count: normalCans)),
          const SizedBox(width: 12),
          Expanded(child: _CanCard(label: 'Cool Cans', count: coolCans, isCool: true)),
        ],
      ),
    );
  }
}

class _CanCard extends StatelessWidget {
  const _CanCard({
    required this.label,
    required this.count,
    this.isCool = false,
  });

  final String label;
  final int count;
  final bool isCool;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: MonthlySummaryColors.canCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MonthlySummaryColors.canCardBorder),
      ),
      child: Row(
        children: [
          _WaterJugIcon(isCool: isCool),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: MonthlySummaryColors.valueNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: MonthlySummaryColors.statBlue,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Water jug icon on the left (mockup: line-style jug, cool variant with snowflake).
class _WaterJugIcon extends StatelessWidget {
  const _WaterJugIcon({required this.isCool});

  final bool isCool;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.local_drink_outlined,
            size: 44,
            color: MonthlySummaryColors.statBlue.withValues(alpha: 0.9),
          ),
          if (isCool)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: MonthlySummaryColors.canCardBorder),
                ),
                child: const Icon(
                  Icons.ac_unit_rounded,
                  size: 13,
                  color: MonthlySummaryColors.statBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class MonthlySummaryTotalCard extends StatelessWidget {
  const MonthlySummaryTotalCard({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: MonthlySummaryColors.totalGreenBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Total Amount',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: MonthlySummaryColors.labelGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyUtils.format(amount),
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: MonthlySummaryColors.totalGreen,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlySummaryPaymentCard extends StatelessWidget {
  const MonthlySummaryPaymentCard({
    super.key,
    required this.stats,
    required this.balance,
  });

  final MonthlyStats stats;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final statusColor = stats.isPaid ? MonthlySummaryColors.totalGreen : MonthlySummaryColors.statusOrange;
    final statusText = stats.statusLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: MonthlySummaryColors.paymentCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Payment Status',
                      style: GoogleFonts.poppins(fontSize: 12, color: MonthlySummaryColors.labelGrey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: MonthlySummaryColors.cardBorder),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Balance',
                      style: GoogleFonts.poppins(fontSize: 12, color: MonthlySummaryColors.labelGrey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyUtils.format(balance.clamp(0, double.infinity)),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: MonthlySummaryColors.balanceRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthlySummaryInfoBanner extends StatelessWidget {
  const MonthlySummaryInfoBanner({super.key, required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final dateLabel = DateFormat('d MMM yyyy').format(lastDay);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: MonthlySummaryColors.infoBannerBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 20, color: MonthlySummaryColors.statBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Customer will pay once per month. Bill will be generated on $dateLabel.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  height: 1.45,
                  color: MonthlySummaryColors.labelGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlySummaryPdfButton extends StatelessWidget {
  const MonthlySummaryPdfButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: MonthlySummaryColors.primaryBtn,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            child: const Text('View Monthly Bill (PDF)'),
          ),
        ),
      ),
    );
  }
}

class MonthlySummaryScaffold extends StatelessWidget {
  const MonthlySummaryScaffold({super.key, required this.child});

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
