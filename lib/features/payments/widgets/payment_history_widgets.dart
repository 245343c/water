import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/data/models/payment_method.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class PaymentHistoryColors {
  static const Color screenBg = AppColors.surface;
  static const Color titleNavy = AppColors.textPrimary;
  static const Color valueNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color cardBorder = AppColors.cardBorder;
}

class PaymentHistoryHeader extends StatelessWidget {
  const PaymentHistoryHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Payment History',
      subtitle: 'Collections and monthly records',
      onBack: onBack,
    );
  }
}

class PaymentHistoryCustomerBar extends StatelessWidget {
  const PaymentHistoryCustomerBar({
    super.key,
    required this.customer,
    required this.colorIndex,
  });

  final Customer customer;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final bg = CustomersColors
        .avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
                fontSize: 15,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PaymentHistoryColors.titleNavy,
                  ),
                ),
                Text(
                  customer.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: PaymentHistoryColors.labelGrey,
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

class PaymentHistoryHeroCard extends StatelessWidget {
  const PaymentHistoryHeroCard({
    super.key,
    required this.totalPaid,
    required this.paymentCount,
  });

  final double totalPaid;
  final int paymentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Collected',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  CurrencyUtils.format(totalPaid),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$paymentCount',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Payments',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.9),
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

class PaymentHistoryList extends StatelessWidget {
  const PaymentHistoryList({super.key, required this.payments});

  final List<Payment> payments;

  Map<String, List<Payment>> get _grouped {
    final map = <String, List<Payment>>{};
    for (final p in payments) {
      final key = p.date.monthYear;
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 56,
              color: PaymentHistoryColors.labelGrey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No payments yet',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: PaymentHistoryColors.titleNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Recorded payments will appear here.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: PaymentHistoryColors.labelGrey,
              ),
            ),
          ],
        ),
      );
    }

    final groups = _grouped.entries.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in groups) ...[
            _PaymentMonthHeader(label: group.key),
            ...group.value.map((p) => _PaymentTimelineTile(payment: p)),
          ],
        ],
      ),
    );
  }
}

class _PaymentMonthHeader extends StatelessWidget {
  const _PaymentMonthHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: PaymentHistoryColors.statGreen,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PaymentHistoryColors.titleNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTimelineTile extends StatelessWidget {
  const _PaymentTimelineTile({required this.payment});

  final Payment payment;

  IconData _methodIcon(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.cash => Icons.payments_outlined,
      PaymentMethod.upi => Icons.qr_code_2_rounded,
      PaymentMethod.other => Icons.receipt_long_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PaymentHistoryColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PaymentHistoryColors.statGreen.withValues(alpha: 0.15),
                  PaymentHistoryColors.statGreen.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: PaymentHistoryColors.statGreen.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              _methodIcon(payment.method),
              color: PaymentHistoryColors.statGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyUtils.format(payment.amount),
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: PaymentHistoryColors.statGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.date.fullDate,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: PaymentHistoryColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.method.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: PaymentHistoryColors.statGreen,
                  ),
                ),
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: 100,
                  child: Text(
                    payment.notes!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: PaymentHistoryColors.labelGrey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentHistoryScaffold extends StatelessWidget {
  const PaymentHistoryScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PremiumResponsiveBody(maxWidth: 1180, child: child),
    );
  }
}
