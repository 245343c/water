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
  static const Color screenBg = Color(0xFFF3F4F6);

  static BoxDecoration get borderedCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

// ─── Header ─────────────────────────────────────────────────────────────────

class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({super.key, required this.onBack, required this.onEdit});
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
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
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

// ─── Profile Section ─────────────────────────────────────────────────────────

class CustomerProfileSection extends StatelessWidget {
  const CustomerProfileSection({super.key, required this.customer, required this.colorIndex});
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
            radius: 26,
            backgroundColor: bg,
            child: Text(
              customer.initials,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: CustomerDetailColors.statBlue),
                    const SizedBox(width: 5),
                    Text(
                      customer.phone,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: CustomerDetailColors.titleNavy),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.chat, color: CustomerDetailColors.whatsapp, size: 18),
                  ],
                ),
                if (customer.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.mail_outline, size: 13, color: CustomerDetailColors.labelGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.email,
                        style: GoogleFonts.poppins(fontSize: 12, color: CustomerDetailColors.labelGrey),
                      ),
                    ),
                  ]),
                ],
                if (customer.place.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined, size: 13, color: CustomerDetailColors.labelGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.place,
                          style: GoogleFonts.poppins(fontSize: 12, color: CustomerDetailColors.labelGrey),
                        ),
                      ),
                    ],
                  ),
                ],
                if (customer.address.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.home_outlined, size: 13, color: CustomerDetailColors.labelGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          customer.address,
                          style: GoogleFonts.poppins(fontSize: 12, height: 1.4, color: CustomerDetailColors.labelGrey),
                        ),
                      ),
                    ],
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

// ─── Balance Hero ─────────────────────────────────────────────────────────────

enum BalanceStatus { paid, pending, overdue }

class CustomerBalanceHero extends StatelessWidget {
  const CustomerBalanceHero({
    super.key,
    required this.totalBalance,
    required this.stats,
    required this.month,
  });

  final double totalBalance;
  final MonthlyStats stats;
  final DateTime month;

  BalanceStatus get _status {
    if (totalBalance <= 0) return BalanceStatus.paid;
    if (stats.isPending) return BalanceStatus.pending;
    return BalanceStatus.overdue;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final (bgColor, borderColor, textColor, badgeBg, badgeFg, statusLabel) = switch (status) {
      BalanceStatus.paid => (
          const Color(0xFFF0FDF4),
          const Color(0xFF86EFAC),
          const Color(0xFF15803D),
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
          'PAID',
        ),
      BalanceStatus.pending => (
          const Color(0xFFFFF7ED),
          const Color(0xFFFDBA74),
          const Color(0xFFEA580C),
          const Color(0xFFFFF7ED),
          const Color(0xFFEA580C),
          'PENDING',
        ),
      BalanceStatus.overdue => (
          const Color(0xFFFEF2F2),
          const Color(0xFFFCA5A5),
          const Color(0xFFDC2626),
          const Color(0xFFFEE2E2),
          const Color(0xFFDC2626),
          'OVERDUE',
        ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding Balance',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyUtils.format(totalBalance.clamp(0, double.infinity)),
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: textColor, height: 1.1),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeFg.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: badgeFg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              _HeroMetric(
                label: '${month.monthYear} Billed',
                value: CurrencyUtils.format(stats.totalAmount),
                color: textColor.withValues(alpha: 0.8),
              ),
              Container(width: 1, height: 28, color: borderColor),
              _HeroMetric(
                label: 'Paid This Month',
                value: CurrencyUtils.format(stats.paidAmount),
                color: CustomerDetailColors.statGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: CustomerDetailColors.labelGrey)),
        ],
      ),
    );
  }
}

// ─── Overview Card (with month navigation) ───────────────────────────────────

class CustomerOverviewCard extends StatelessWidget {
  const CustomerOverviewCard({
    super.key,
    required this.month,
    required this.stats,
    this.onViewAll,
    this.onPrevMonth,
    this.onNextMonth,
  });

  final DateTime month;
  final MonthlyStats stats;
  final VoidCallback? onViewAll;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: CustomerDetailColors.borderedCard,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Deliveries',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: CustomerDetailColors.titleNavy),
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'View all',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: CustomerDetailColors.linkBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Month navigation ─────────────────────────────────────────────
          Row(
            children: [
              _MonthNavBtn(icon: Icons.chevron_left, onTap: onPrevMonth),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  month.monthYear,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isCurrentMonth ? CustomerDetailColors.statBlue : CustomerDetailColors.labelGrey,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _MonthNavBtn(
                icon: Icons.chevron_right,
                onTap: _isCurrentMonth ? null : onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CustomerDetailColors.cardBorder),
          const SizedBox(height: 4),

          // ── Metrics ──────────────────────────────────────────────────────
          MonthlyMetricsList(
            stats: stats,
            labelColor: CustomerDetailColors.labelGrey,
            valueColor: CustomerDetailColors.statBlue,
            titleNavy: CustomerDetailColors.titleNavy,
            dividerColor: CustomerDetailColors.cardBorder,
          ),
        ],
      ),
    );
  }
}

class _MonthNavBtn extends StatelessWidget {
  const _MonthNavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? CustomerDetailColors.statBlue.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? CustomerDetailColors.statBlue.withValues(alpha: 0.3) : CustomerDetailColors.cardBorder,
          ),
        ),
        child: Icon(icon, size: 18, color: enabled ? CustomerDetailColors.statBlue : CustomerDetailColors.cardBorder),
      ),
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────────────────────────

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.onAddDelivery,
    required this.onRecordPayment,
    required this.onViewBills,
    required this.onCall,
    required this.onViewHistory,
    this.customerPhone,
  });

  final VoidCallback onAddDelivery;
  final VoidCallback onRecordPayment;
  final VoidCallback onViewBills;
  final VoidCallback onCall;
  final VoidCallback onViewHistory;
  final String? customerPhone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: CustomerDetailColors.titleNavy),
          ),
          const SizedBox(height: 8),
          _PrimaryAction(label: 'Add Delivery', icon: Icons.water_drop, onTap: onAddDelivery),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SecondaryAction(
                  label: 'Record\nPayment',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: CustomerDetailColors.statGreen,
                  bgColor: const Color(0xFFDCFCE7),
                  onTap: onRecordPayment,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryAction(
                  label: 'Monthly\nBill',
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFEDE9FE),
                  onTap: onViewBills,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryAction(
                  label: 'History',
                  icon: Icons.history_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  bgColor: const Color(0xFFE0F2FE),
                  onTap: onViewHistory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SecondaryAction(
                  label: 'Call',
                  icon: Icons.phone_outlined,
                  iconColor: const Color(0xFFEA580C),
                  bgColor: const Color(0xFFFFF7ED),
                  onTap: onCall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A73E8), Color(0xFF1558B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor, height: 1.2),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recent Deliveries Card ──────────────────────────────────────────────────

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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: CustomerDetailColors.borderedCard,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Deliveries',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: CustomerDetailColors.titleNavy),
                ),
              ),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    'View all',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: CustomerDetailColors.linkBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (deliveries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 36, color: CustomerDetailColors.labelGrey.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'No deliveries yet',
                    style: GoogleFonts.poppins(color: CustomerDetailColors.labelGrey, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...List.generate(deliveries.length, (i) {
              final d = deliveries[i];
              return Column(
                children: [
                  _RecentRow(delivery: d, onTap: onItemTap != null ? () => onItemTap!(d) : null),
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CustomerDetailColors.statBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.water_drop_outlined, size: 18, color: CustomerDetailColors.statBlue),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.date.fullDate,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: CustomerDetailColors.valueNavy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    delivery.itemsSummary,
                    style: GoogleFonts.poppins(fontSize: 11, color: CustomerDetailColors.labelGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyUtils.format(delivery.totalAmount),
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: CustomerDetailColors.valueNavy),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Delete Section ──────────────────────────────────────────────────────────

class DeleteCustomerSection extends StatelessWidget {
  const DeleteCustomerSection({super.key, required this.onDelete});
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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

// ─── Scaffold ────────────────────────────────────────────────────────────────

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

