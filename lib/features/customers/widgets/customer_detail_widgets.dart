import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
import 'package:sri_sai_ro_water/data/models/payment.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class CustomerDetailColors {
  static const Color titleNavy = Color(0xFF1E3A8A);
  static const Color valueNavy = Color(0xFF1E40AF);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color statOrange = Color(0xFFEA580C);
  static const Color statRed = Color(0xFFDC2626);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color linkBlue = Color(0xFF1A73E8);
  static const Color whatsapp = Color(0xFF25D366);

  static BoxDecoration get borderedCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      );
}

class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({
    super.key,
    required this.onBack,
    required this.onEdit,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 8, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Customer Details',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class CustomerProfileSection extends StatelessWidget {
  const CustomerProfileSection({
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: bg,
            child: Text(
              customer.initials,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
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
                    color: CustomerDetailColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      customer.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: CustomerDetailColors.titleNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chat, color: CustomerDetailColors.whatsapp, size: 20),
                  ],
                ),
                if (customer.email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    customer.email,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: CustomerDetailColors.labelGrey,
                    ),
                  ),
                ],
                if (customer.place.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: CustomerDetailColors.labelGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.place,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: CustomerDetailColors.labelGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  customer.address,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.45,
                    color: CustomerDetailColors.labelGrey,
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

class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    super.key,
    required this.month,
    required this.stats,
  });

  final DateTime month;
  final MonthlyStats stats;

  @override
  Widget build(BuildContext context) {
    final statusColor = stats.isPaid ? CustomerDetailColors.statGreen : CustomerDetailColors.statOrange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: CustomerDetailColors.borderedCard,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month Summary (${month.monthYear})',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.titleNavy,
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Normal Cans',
                    value: '${stats.normalCans}',
                    valueColor: CustomerDetailColors.statBlue,
                  ),
                ),
                const _VertDivider(),
                Expanded(
                  child: _StatColumn(
                    label: 'Cool Cans',
                    value: '${stats.coolCans}',
                    valueColor: CustomerDetailColors.statBlue,
                  ),
                ),
                const _VertDivider(),
                Expanded(
                  child: _StatColumn(
                    label: 'Total Amount',
                    value: CurrencyUtils.format(stats.totalAmount),
                    valueColor: CustomerDetailColors.statGreen,
                    compactValue: true,
                  ),
                ),
                const _VertDivider(),
                Expanded(
                  child: _StatColumn(
                    label: 'Status',
                    value: stats.statusLabel,
                    valueColor: statusColor,
                    compactValue: true,
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

class AccountSummaryCard extends StatelessWidget {
  const AccountSummaryCard({
    super.key,
    required this.balance,
    required this.lastPayment,
    required this.paymentFrequency,
  });

  final double balance;
  final Payment? lastPayment;
  final String paymentFrequency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: CustomerDetailColors.borderedCard,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Summary',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.titleNavy,
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    label: 'Total Pending',
                    value: CurrencyUtils.format(balance.clamp(0, double.infinity)),
                    valueColor: CustomerDetailColors.statRed,
                  ),
                ),
                const _VertDivider(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Last Payment',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: CustomerDetailColors.labelGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (lastPayment != null) ...[
                        Text(
                          lastPayment!.date.fullDate,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: CustomerDetailColors.titleNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyUtils.format(lastPayment!.amount),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: CustomerDetailColors.statGreen,
                          ),
                        ),
                      ] else
                        Text(
                          '—',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: CustomerDetailColors.labelGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                const _VertDivider(),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Payment Frequency',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: CustomerDetailColors.labelGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(Icons.calendar_month, color: CustomerDetailColors.statBlue, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        paymentFrequency,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CustomerDetailColors.titleNavy,
                        ),
                      ),
                    ],
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

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onAddDelivery,
    required this.onViewHistory,
    required this.onViewBills,
    required this.onRecordPayment,
  });

  final VoidCallback onAddDelivery;
  final VoidCallback onViewHistory;
  final VoidCallback onViewBills;
  final VoidCallback onRecordPayment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.titleNavy,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  label: 'Add Delivery',
                  icon: Icons.water_drop,
                  bg: const Color(0xFF1A73E8),
                  iconColor: Colors.white,
                  onTap: onAddDelivery,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  label: 'View History',
                  icon: Icons.description_outlined,
                  bg: const Color(0xFFE8F0FE),
                  iconColor: CustomerDetailColors.statBlue,
                  onTap: onViewHistory,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  label: 'View Bills',
                  icon: Icons.receipt_long_outlined,
                  bg: const Color(0xFFE8F0FE),
                  iconColor: CustomerDetailColors.statBlue,
                  onTap: onViewBills,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  label: 'Record Payment',
                  icon: Icons.account_balance_wallet_outlined,
                  bg: const Color(0xFFDCFCE7),
                  iconColor: CustomerDetailColors.statGreen,
                  onTap: onRecordPayment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentDeliveriesCard extends StatelessWidget {
  const RecentDeliveriesCard({
    super.key,
    required this.deliveries,
    this.onViewAll,
    this.onItemTap,
  });

  final List<Delivery> deliveries;
  final VoidCallback? onViewAll;
  final void Function(Delivery d)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      decoration: CustomerDetailColors.borderedCard,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Deliveries',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.titleNavy,
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
                      color: CustomerDetailColors.linkBlue,
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
                'No deliveries yet',
                style: GoogleFonts.poppins(color: CustomerDetailColors.labelGrey, fontSize: 13),
              ),
            )
          else
            ...List.generate(deliveries.length, (i) {
              final d = deliveries[i];
              return Column(
                children: [
                  _RecentRow(
                    delivery: d,
                    onTap: onItemTap != null ? () => onItemTap!(d) : null,
                  ),
                  if (i < deliveries.length - 1)
                    const Divider(height: 1, color: CustomerDetailColors.cardBorder),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.delivery, this.onTap});

  final Delivery delivery;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
                  color: CustomerDetailColors.valueNavy,
                ),
              ),
            ),
            Expanded(
              child: Text(
                delivery.cansSummary,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CustomerDetailColors.valueNavy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              CurrencyUtils.format(delivery.totalAmount),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CustomerDetailColors.valueNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    this.compactValue = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 10, color: CustomerDetailColors.labelGrey),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: compactValue ? 16 : 22,
            fontWeight: FontWeight.w800,
            color: valueColor,
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
    return const VerticalDivider(
      width: 1,
      thickness: 1,
      color: CustomerDetailColors.cardBorder,
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: CustomerDetailColors.labelGrey,
              height: 1.2,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class DeleteCustomerSection extends StatelessWidget {
  const DeleteCustomerSection({super.key, required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          label: Text(
            'Delete Customer',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: CustomerDetailColors.statRed,
            side: const BorderSide(color: CustomerDetailColors.statRed),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class CustomerDetailScaffold extends StatelessWidget {
  const CustomerDetailScaffold({super.key, required this.child});

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
