import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/core/widgets/monthly_metrics_list.dart';
import 'package:sri_sai_ro_water/data/models/monthly_stats.dart';
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
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
                    color: CustomerDetailColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
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
                const SizedBox(height: 4),
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

/// Quick glance at this month — full account & payments on Monthly Summary (View all).
class CustomerOverviewCard extends StatelessWidget {
  const CustomerOverviewCard({
    super.key,
    required this.month,
    required this.stats,
    this.onViewAll,
  });

  final DateTime month;
  final MonthlyStats stats;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      title: 'This Month Summary',
      actionLabel: onViewAll != null ? 'View all' : null,
      onAction: onViewAll,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.hasDeliveries ? 'Delivered this month' : month.monthYear,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: CustomerDetailColors.labelGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            month.monthYear,
            style: GoogleFonts.poppins(fontSize: 12, color: CustomerDetailColors.labelGrey),
          ),
        ],
      ),
      child: MonthlyMetricsList(
        stats: stats,
        labelColor: CustomerDetailColors.labelGrey,
        valueColor: CustomerDetailColors.statBlue,
        titleNavy: CustomerDetailColors.titleNavy,
        dividerColor: CustomerDetailColors.cardBorder,
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.title,
    required this.child,
    this.footer,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final Widget? footer;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: CustomerDetailColors.borderedCard,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.titleNavy,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 2),
                      footer!,
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    actionLabel!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CustomerDetailColors.linkBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _OverviewStatCell extends StatelessWidget {
  const _OverviewStatCell({
    required this.label,
    required this.value,
    required this.valueColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool compact;

  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: CustomerDetailColors.labelGrey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: compact ? 16 : 22,
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(
      width: 1,
      thickness: 1,
      color: CustomerDetailColors.cardBorder,
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
                delivery.itemsSummary,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CustomerDetailColors.valueNavy,
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
                color: CustomerDetailColors.valueNavy,
              ),
            ),
          ],
        ),
      ),
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
