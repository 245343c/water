import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/core/widgets/monthly_metrics_list.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class MonthlySummaryColors {
  static const Color screenBg = Color(0xFFF3F4F6);
  static const Color titleNavy = Color(0xFF1E3A8A);
  static const Color valueNavy = Color(0xFF1E40AF);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color statOrange = Color(0xFFEA580C);
  static const Color statRed = Color(0xFFDC2626);
  static const Color linkBlue = Color(0xFF1A73E8);
  static const Color primaryBtn = Color(0xFF1A73E8);
  static const Color whatsapp = Color(0xFF25D366);

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

class MonthlySummaryHeader extends StatelessWidget {
  const MonthlySummaryHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 8, 14),
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

class MonthlySummaryCustomerBar extends StatelessWidget {
  const MonthlySummaryCustomerBar({
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
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: bg,
            child: Text(
              customer.initials,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
                    color: MonthlySummaryColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: MonthlySummaryColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: MonthlySummaryColors.whatsapp.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.chat, color: MonthlySummaryColors.whatsapp, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlySummaryMonthNav extends StatelessWidget {
  const MonthlySummaryMonthNav({
    super.key,
    required this.month,
    required this.onPrev,
    required this.onNext,
    this.canGoNext = true,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: MonthlySummaryColors.cardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: MonthlySummaryColors.labelGrey),
              onPressed: onPrev,
            ),
            Expanded(
              child: Text(
                month.monthYear,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MonthlySummaryColors.titleNavy,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: canGoNext ? MonthlySummaryColors.labelGrey : MonthlySummaryColors.labelGrey.withValues(alpha: 0.35),
              ),
              onPressed: canGoNext ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlySummaryStatsCard extends StatelessWidget {
  const MonthlySummaryStatsCard({super.key, required this.stats});

  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: MonthlySummaryColors.cardDecoration,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month Summary',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MonthlySummaryColors.titleNavy,
              ),
            ),
            const SizedBox(height: 8),
            MonthlyMetricsList(
              stats: stats,
              labelColor: MonthlySummaryColors.labelGrey,
              valueColor: MonthlySummaryColors.statBlue,
              titleNavy: MonthlySummaryColors.titleNavy,
              dividerColor: MonthlySummaryColors.cardBorder,
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlySummaryAccountCard extends StatelessWidget {
  const MonthlySummaryAccountCard({
    super.key,
    required this.stats,
    required this.balance,
  });

  final MonthlyStats stats;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final statusColor = stats.isPaid ? MonthlySummaryColors.statGreen : MonthlySummaryColors.statOrange;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: MonthlySummaryColors.cardDecoration,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Summary',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: MonthlySummaryColors.titleNavy,
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      label: 'Payment Status',
                      value: stats.statusLabel,
                      color: statusColor,
                      compact: true,
                    ),
                  ),
                  const _VertDivider(),
                  Expanded(
                    child: _StatCell(
                      label: 'Balance Due',
                      value: CurrencyUtils.format(balance.clamp(0, double.infinity)),
                      color: MonthlySummaryColors.statRed,
                      compact: true,
                    ),
                  ),
                  const _VertDivider(),
                  Expanded(
                    child: _StatCell(
                      label: 'Paid This Month',
                      value: CurrencyUtils.format(stats.paidAmount),
                      color: MonthlySummaryColors.statGreen,
                      compact: true,
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

class MonthlyDeliveriesSection extends StatelessWidget {
  const MonthlyDeliveriesSection({
    super.key,
    required this.deliveries,
    this.onViewAll,
  });

  final List<Delivery> deliveries;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: MonthlySummaryColors.cardDecoration,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Deliveries this month',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MonthlySummaryColors.titleNavy,
                    ),
                  ),
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Text(
                      'View all',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MonthlySummaryColors.linkBlue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (deliveries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No deliveries this month',
                  style: GoogleFonts.poppins(fontSize: 13, color: MonthlySummaryColors.labelGrey),
                ),
              )
            else
              ...List.generate(deliveries.length.clamp(0, 5), (i) {
                final d = deliveries[i];
                return Column(
                  children: [
                    _DeliveryRow(delivery: d),
                    if (i < deliveries.length.clamp(0, 5) - 1)
                      const Divider(height: 1, color: MonthlySummaryColors.divider),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.delivery});

  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              delivery.date.fullDate,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MonthlySummaryColors.valueNavy,
              ),
            ),
          ),
          Expanded(
            child: Text(
              delivery.itemsSummary,
              style: GoogleFonts.poppins(fontSize: 13, color: MonthlySummaryColors.valueNavy),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            CurrencyUtils.format(delivery.totalAmount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MonthlySummaryColors.valueNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyPaymentsSection extends StatelessWidget {
  const MonthlyPaymentsSection({
    super.key,
    required this.payments,
    this.onViewAllPayments,
  });

  final List<Payment> payments;
  final VoidCallback? onViewAllPayments;

  @override
  Widget build(BuildContext context) {
    final total = payments.fold<double>(0, (s, p) => s + p.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        decoration: MonthlySummaryColors.cardDecoration,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payments this month',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: MonthlySummaryColors.titleNavy,
                    ),
                  ),
                ),
                if (onViewAllPayments != null)
                  GestureDetector(
                    onTap: onViewAllPayments,
                    child: Text(
                      'View all',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MonthlySummaryColors.linkBlue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No payments recorded for this month',
                    style: GoogleFonts.poppins(fontSize: 13, color: MonthlySummaryColors.labelGrey),
                  ),
                ),
              )
            else ...[
              Text(
                'Total received: ${CurrencyUtils.format(total)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MonthlySummaryColors.statGreen,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(payments.length, (i) {
                final p = payments[i];
                return Column(
                  children: [
                    _PaymentRow(payment: p),
                    if (i < payments.length - 1)
                      const Divider(height: 1, color: MonthlySummaryColors.divider),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MonthlySummaryColors.statGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_outlined, size: 20, color: MonthlySummaryColors.statGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.date.fullDate,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MonthlySummaryColors.valueNavy,
                  ),
                ),
                Text(
                  payment.method.label,
                  style: GoogleFonts.poppins(fontSize: 12, color: MonthlySummaryColors.labelGrey),
                ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.format(payment.amount),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MonthlySummaryColors.statGreen,
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: MonthlySummaryColors.cardDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: MonthlySummaryColors.statBlue),
            const SizedBox(width: 10),
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
    return Container(
      color: MonthlySummaryColors.screenBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: MonthlySummaryColors.primaryBtn,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: const Text('View Monthly Bill (PDF)'),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 10, color: MonthlySummaryColors.labelGrey),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: compact ? 15 : 20,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider();

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(width: 1, thickness: 1, color: MonthlySummaryColors.divider);
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
