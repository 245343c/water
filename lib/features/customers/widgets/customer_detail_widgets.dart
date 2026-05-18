import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/month_wheel_scroll.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
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

// ─── Total Pending card ───────────────────────────────────────────────────────

class CustomerPendingCard extends StatelessWidget {
  const CustomerPendingCard({
    super.key,
    required this.totalPending,
    required this.previousPending,
    required this.monthStats,
  });

  /// All-time outstanding (previous + this month − payments).
  final double totalPending;
  /// Unpaid balance carried from months before the current month.
  final double previousPending;
  final MonthlyStats monthStats;

  bool get _isPaid => totalPending <= 0;

  @override
  Widget build(BuildContext context) {
    final double pendingAmount = totalPending.isNegative ? 0.0 : totalPending;
    final double priorDue = previousPending.isNegative ? 0.0 : previousPending;
    final double thisMonthBill = monthStats.totalAmount;
    final double paidThisMonth = monthStats.paidAmount;

    final textColor =
        _isPaid ? CustomerDetailColors.statGreen : CustomerDetailColors.statOrange;
    final bgColor = _isPaid ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED);
    final statusLabel = _isPaid ? 'PAID' : 'PENDING';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CustomerDetailColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: textColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pending',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CustomerDetailColors.labelGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.format(pendingAmount),
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: textColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Row(
              children: [
              Expanded(
                child: _PendingBreakdownTile(
                  label: 'Previous Due',
                  value: CurrencyUtils.format(priorDue),
                  icon: Icons.history_rounded,
                  color: const Color(0xFF7C3AED),
                  bg: const Color(0xFFF5F3FF),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _PendingBreakdownTile(
                  label: 'This Month',
                  value: CurrencyUtils.format(thisMonthBill),
                  icon: Icons.receipt_long_outlined,
                  color: CustomerDetailColors.statOrange,
                  bg: const Color(0xFFFFF7ED),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _PendingBreakdownTile(
                  label: 'Paid',
                  value: CurrencyUtils.format(paidThisMonth),
                  icon: Icons.check_circle_outline_rounded,
                  color: CustomerDetailColors.statGreen,
                  bg: const Color(0xFFECFDF5),
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

class _PendingBreakdownTile extends StatelessWidget {
  const _PendingBreakdownTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w500,
              color: CustomerDetailColors.labelGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Overview ─────────────────────────────────────────────────────────

/// Up to [limit] recent months that have deliveries or payments.
List<DateTime> monthsWithActivity({
  required int year,
  required int throughMonth,
  required MonthlyStats Function(DateTime month) statsForMonth,
  int limit = 4,
}) {
  final result = <DateTime>[];
  for (var m = throughMonth; m >= 1; m--) {
    final month = DateTime(year, m);
    final stats = statsForMonth(month);
    if (stats.totalAmount > 0 || stats.paidAmount > 0) {
      result.add(month);
      if (result.length >= limit) break;
    }
  }
  return result;
}

class CustomerMonthlyOverviewSection extends StatelessWidget {
  const CustomerMonthlyOverviewSection({
    super.key,
    required this.statsForMonth,
    required this.onMonthTap,
    this.year,
    this.initialMonth,
  });

  final MonthlyStats Function(DateTime month) statsForMonth;
  final void Function(DateTime month) onMonthTap;
  final int? year;
  final int? initialMonth;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final y = year ?? now.year;
    final throughMonth = y == now.year ? now.month : 12;
    final initial = (initialMonth ?? now.month).clamp(1, throughMonth);
    final activeMonths = monthsWithActivity(
      year: y,
      throughMonth: throughMonth,
      statsForMonth: statsForMonth,
      limit: 4,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: CustomerDetailColors.borderedCard,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: CustomerDetailColors.statBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly Overview',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.titleNavy,
                ),
              ),
              const Spacer(),
              Text(
                '$y',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CustomerDetailColors.labelGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (activeMonths.isEmpty)
            Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Text(
                'No activity yet — add a delivery to see months here',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: CustomerDetailColors.labelGrey,
                ),
              ),
            )
          else ...[
            const MonthWheelTableHeader(),
            const SizedBox(height: 8),
            MonthOverviewList(
              months: activeMonths,
              itemBuilder: (context, month) {
                final stats = statsForMonth(month);
                final isCurrent = month.month == initial;
                return _MonthlyOverviewRow(
                  month: month,
                  stats: stats,
                  isCurrentMonth: isCurrent,
                  onTap: () => onMonthTap(month),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Tap a month to open summary',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: CustomerDetailColors.labelGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _MonthPayStatus { none, paid, partial, pending }

_MonthPayStatus _monthPayStatus(MonthlyStats stats) {
  final hasActivity = stats.totalAmount > 0 || stats.paidAmount > 0;
  if (!hasActivity) return _MonthPayStatus.none;
  if (stats.balance <= 0) return _MonthPayStatus.paid;
  if (stats.paidAmount > 0) return _MonthPayStatus.partial;
  return _MonthPayStatus.pending;
}

class _MonthlyOverviewRow extends StatelessWidget {
  const _MonthlyOverviewRow({
    required this.month,
    required this.stats,
    required this.isCurrentMonth,
    required this.onTap,
  });

  final DateTime month;
  final MonthlyStats stats;
  final bool isCurrentMonth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _monthPayStatus(stats);
    final hasActivity = status != _MonthPayStatus.none;

    final (amountColor, rowBg, rowBorder) = switch (status) {
      _MonthPayStatus.paid => (
          CustomerDetailColors.statGreen,
          const Color(0xFFECFDF5),
          const Color(0xFF86EFAC),
        ),
      _MonthPayStatus.partial => (
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          const Color(0xFFFCD34D),
        ),
      _MonthPayStatus.pending => (
          CustomerDetailColors.statOrange,
          const Color(0xFFFFF7ED),
          const Color(0xFFFDBA74),
        ),
      _MonthPayStatus.none => (
          CustomerDetailColors.labelGrey,
          Colors.white,
          const Color(0xFFE5E7EB),
        ),
    };

    final pendingDisplay = stats.balance > 0
        ? CurrencyUtils.format(stats.balance)
        : CurrencyUtils.format(0.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentMonth ? rowBg : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isCurrentMonth ? amountColor.withValues(alpha: 0.45) : rowBorder,
              width: isCurrentMonth ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                  color: amountColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  month.monthName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CustomerDetailColors.titleNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  CurrencyUtils.format(stats.totalAmount),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  pendingDisplay,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: Center(
                  child: _StatusBadge(
                    label: switch (status) {
                      _MonthPayStatus.none => '—',
                      _MonthPayStatus.paid => 'PAID',
                      _MonthPayStatus.partial => 'PART',
                      _MonthPayStatus.pending => 'PENDING',
                    },
                    status: status,
                    isEmpty: !hasActivity,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: CustomerDetailColors.labelGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.status,
    required this.isEmpty,
  });

  final String label;
  final _MonthPayStatus status;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: CustomerDetailColors.labelGrey,
        ),
      );
    }

    final (color, bg) = switch (status) {
      _MonthPayStatus.paid => (
          CustomerDetailColors.statGreen,
          const Color(0xFFDCFCE7),
        ),
      _MonthPayStatus.partial => (
          const Color(0xFFD97706),
          const Color(0xFFFEF3C7),
        ),
      _MonthPayStatus.pending => (
          CustomerDetailColors.statOrange,
          const Color(0xFFFFF7ED),
        ),
      _MonthPayStatus.none => (
          CustomerDetailColors.labelGrey,
          const Color(0xFFF3F4F6),
        ),
    };

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.0,
          ),
        ),
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
  });

  final VoidCallback onAddDelivery;
  final VoidCallback onRecordPayment;
  final VoidCallback onViewBills;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CustomerDetailColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.titleNavy,
            ),
          ),
          const SizedBox(height: 12),
          AddDeliveryBar(onTap: onAddDelivery),
          const SizedBox(height: 12),
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
                  label: 'Call',
                  icon: Icons.phone_outlined,
                  iconColor: CustomerDetailColors.statOrange,
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

/// Full-width gradient bar for adding a delivery (animated van).
class AddDeliveryBar extends StatefulWidget {
  const AddDeliveryBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<AddDeliveryBar> createState() => _AddDeliveryBarState();
}

class _AddDeliveryBarState extends State<AddDeliveryBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drive;

  @override
  void initState() {
    super.initState();
    _drive = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1A73E8), Color(0xFF2563EB)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1A73E8).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _drive,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_drive.value * 10, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add Delivery',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _drive,
                builder: (context, _) {
                  return Opacity(
                    opacity: 0.55 + _drive.value * 0.45,
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  );
                },
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withValues(alpha: 0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: iconColor,
                height: 1.15,
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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

