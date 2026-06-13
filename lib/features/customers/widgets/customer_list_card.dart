import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/constants/empty_can_balance.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_route_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

enum CustomerPaymentCategory { paid, pending, overdue }

class CustomerListCard extends StatelessWidget {
  const CustomerListCard({
    super.key,
    required this.customer,
    required this.colorIndex,
    required this.unitsThisMonth,
    required this.lastDeliveryLabel,
    required this.balance,
    required this.category,
    required this.onTap,
    this.emptyJarsWithCustomer = 0,
    this.routeName,
    this.routeUnassigned = false,
  });

  final Customer customer;
  final int colorIndex;
  final int unitsThisMonth;
  final String lastDeliveryLabel;
  final double balance;
  final CustomerPaymentCategory category;
  final VoidCallback onTap;
  final int emptyJarsWithCustomer;
  final String? routeName;
  final bool routeUnassigned;

  @override
  Widget build(BuildContext context) {
    final accent = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];
    final owed = balance > 0;
    final jarsLabel = emptyJarsDueLabel(emptyJarsWithCustomer);
    final jarsWarning = emptyCanCountIsWarning(emptyJarsWithCustomer);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CustomersColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TintedAvatar(initials: customer.initials, accent: accent),
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
                          color: CustomersColors.titleNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customer.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: CustomersColors.labelGrey,
                        ),
                      ),
                      if (routeName != null) ...[
                        const SizedBox(height: 6),
                        CustomerRouteBadge(
                          routeName: routeName!,
                          unassigned: routeUnassigned,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        _activitySummary(unitsThisMonth, lastDeliveryLabel),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: CustomersColors.labelGrey,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      owed ? CurrencyUtils.format(balance) : CurrencyUtils.format(0),
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: owed ? CustomersColors.balanceRed : CustomersColors.balanceGreen,
                      ),
                    ),
                    if (jarsLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            size: 13,
                            color: jarsWarning
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFEA580C),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              jarsLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: jarsWarning
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFEA580C),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    _StatusBadge(category: category),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _activitySummary(int unitsThisMonth, String lastDeliveryLabel) {
  if (unitsThisMonth <= 0) {
    return lastDeliveryLabel == 'No delivery yet'
        ? 'No deliveries this month'
        : 'Last delivery $lastDeliveryLabel';
  }
  return '$unitsThisMonth units this month · Last delivery $lastDeliveryLabel';
}

class _TintedAvatar extends StatelessWidget {
  const _TintedAvatar({required this.initials, required this.accent});

  final String initials;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: accent.withValues(alpha: 0.14),
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.category});

  final CustomerPaymentCategory category;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (category) {
      CustomerPaymentCategory.paid => (
          const Color(0xFFECFDF5),
          const Color(0xFF16A34A),
          'Paid',
        ),
      CustomerPaymentCategory.pending => (
          const Color(0xFFFFF7ED),
          const Color(0xFFEA580C),
          'Pending',
        ),
      CustomerPaymentCategory.overdue => (
          const Color(0xFFFEF2F2),
          const Color(0xFFDC2626),
          'Overdue',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

String lastDeliveryRelativeLabel(DateTime? date) {
  if (date == null) return 'No delivery yet';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return date.dayMonth;
}

CustomerPaymentCategory customerPaymentCategory({
  required double totalBalance,
  required double monthBalance,
  required double priorBalance,
  required double monthTotal,
}) {
  if (priorBalance > 0 && totalBalance > 0) return CustomerPaymentCategory.overdue;
  if (totalBalance <= 0) return CustomerPaymentCategory.paid;
  if (monthTotal > 0 && monthBalance > 0) return CustomerPaymentCategory.pending;
  if (totalBalance > 0) return CustomerPaymentCategory.pending;
  return CustomerPaymentCategory.paid;
}
