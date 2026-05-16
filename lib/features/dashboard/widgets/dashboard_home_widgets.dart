import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';

abstract final class DashboardColors {
  static const Color bgTop = Color(0xFF000B2E);
  static const Color bgMid = Color(0xFF001247);
  static const Color bgBottom = Color(0xFF002868);
  static const Color cardTitle = Color(0xFF1E3A8A);
  static const Color statGreen = Color(0xFF10B981);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color statRed = Color(0xFFEF4444);
  static const Color statPurple = Color(0xFF7C3AED);
  static const Color statTeal = Color(0xFF0D9488);
  static const Color linkBlue = Color(0xFF1A73E8);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color chipBg = Color(0xFFF3F4F6);
  static const Color statCellBg = Color(0xFFFAFBFC);
  static const Color statCellBorder = Color(0xFFE5E7EB);

  static const List<Color> deliveryIconBgs = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
  ];

  static BoxDecoration get screenGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgMid, bgBottom],
        ),
      );

  static BoxDecoration get whiteCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      );
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                onPressed: () {},
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: const BoxDecoration(
                    color: DashboardColors.statRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({
    super.key,
    required this.onAddDelivery,
    required this.onAddCustomer,
  });

  final VoidCallback onAddDelivery;
  final VoidCallback onAddCustomer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardColors.whiteCard,
      padding: const EdgeInsets.all(6),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.local_shipping_rounded,
                iconBg: const Color(0xFF1A73E8),
                label: 'Add Delivery',
                subtitle: 'Log cans today',
                onTap: onAddDelivery,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 10),
              color: DashboardColors.statCellBorder,
            ),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.person_add_alt_1_rounded,
                iconBg: DashboardColors.statGreen,
                label: 'Add Customer',
                subtitle: 'New account',
                onTap: onAddCustomer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconBg, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: DashboardColors.labelGrey,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: iconBg.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardOverviewData {
  const DashboardOverviewData({
    required this.totalSales,
    required this.totalDeliveries,
    required this.totalCans,
    required this.activeCustomers,
    required this.paidThisMonth,
    required this.pendingAmount,
  });

  final String totalSales;
  final String totalDeliveries;
  final String totalCans;
  final String activeCustomers;
  final String paidThisMonth;
  final String pendingAmount;
}

class DashboardOverviewCard extends StatelessWidget {
  const DashboardOverviewCard({
    super.key,
    required this.month,
    required this.onMonthTap,
    required this.data,
  });

  final DateTime month;
  final VoidCallback onMonthTap;
  final DashboardOverviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardColors.whiteCard,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'This Month Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.cardTitle,
                  ),
                ),
              ),
              _MonthChip(month: month, onTap: onMonthTap),
            ],
          ),
          const SizedBox(height: 12),
          _SalesHero(
            totalSales: data.totalSales,
            deliveries: data.totalDeliveries,
            cans: data.totalCans,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MoneyChip(
                  label: 'Paid',
                  value: data.paidThisMonth,
                  color: DashboardColors.statGreen,
                  bg: const Color(0xFFECFDF5),
                  icon: Icons.verified_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MoneyChip(
                  label: 'Pending',
                  value: data.pendingAmount,
                  color: DashboardColors.statRed,
                  bg: const Color(0xFFFEF2F2),
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CompactMetric(
                  value: data.totalDeliveries,
                  label: 'Deliveries',
                  color: DashboardColors.statGreen,
                  icon: Icons.local_shipping_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactMetric(
                  value: data.totalCans,
                  label: 'Cans',
                  color: DashboardColors.statBlue,
                  icon: Icons.water_drop_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactMetric(
                  value: data.activeCustomers,
                  label: 'Customers',
                  color: DashboardColors.statPurple,
                  icon: Icons.groups_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesHero extends StatelessWidget {
  const _SalesHero({
    required this.totalSales,
    required this.deliveries,
    required this.cans,
  });

  final String totalSales;
  final String deliveries;
  final String cans;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardColors.statTeal.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Sales',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    totalSales,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$deliveries deliveries · $cans cans',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _MoneyChip extends StatelessWidget {
  const _MoneyChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: DashboardColors.labelGrey,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
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

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: DashboardColors.labelGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.month, required this.onTap});

  final DateTime month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardColors.chipBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                month.monthYear,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardRecentCard extends StatelessWidget {
  const DashboardRecentCard({
    super.key,
    required this.deliveries,
    required this.customerNameOf,
    required this.colorIndexOf,
    this.onViewAll,
    this.onItemTap,
    this.onAddDelivery,
  });

  final List<Delivery> deliveries;
  final String Function(String customerId) customerNameOf;
  final int Function(String customerId) colorIndexOf;
  final VoidCallback? onViewAll;
  final void Function(Delivery delivery)? onItemTap;
  final VoidCallback? onAddDelivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardColors.whiteCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DashboardColors.statBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop_outlined, size: 18, color: DashboardColors.statBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recent Deliveries',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.cardTitle,
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
                      color: DashboardColors.linkBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (deliveries.isEmpty)
            _RecentEmptyState(onAddDelivery: onAddDelivery)
          else
            ...List.generate(deliveries.length, (i) {
              final d = deliveries[i];
              final ci = colorIndexOf(d.customerId) % DashboardColors.deliveryIconBgs.length;
              return DashboardRecentTile(
                customerName: customerNameOf(d.customerId),
                iconBg: DashboardColors.deliveryIconBgs[ci],
                delivery: d,
                onTap: onItemTap != null ? () => onItemTap!(d) : null,
                showDivider: i < deliveries.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _RecentEmptyState extends StatelessWidget {
  const _RecentEmptyState({this.onAddDelivery});

  final VoidCallback? onAddDelivery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined, size: 48, color: DashboardColors.labelGrey.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          Text(
            'No deliveries yet',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DashboardColors.labelGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first delivery to see activity here',
            style: GoogleFonts.poppins(fontSize: 12, color: DashboardColors.labelGrey),
          ),
          if (onAddDelivery != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddDelivery,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Delivery'),
              style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.linkBlue,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardRecentTile extends StatelessWidget {
  const DashboardRecentTile({
    super.key,
    required this.customerName,
    required this.iconBg,
    required this.delivery,
    this.onTap,
    this.showDivider = false,
  });

  final String customerName;
  final Color iconBg;
  final Delivery delivery;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (delivery.normalQty > 0) _CanChip(label: '${delivery.normalQty}N'),
                            if (delivery.normalQty > 0 && delivery.coolQty > 0) const SizedBox(width: 6),
                            if (delivery.coolQty > 0) _CanChip(label: '${delivery.coolQty}C', cool: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        delivery.date.deliveryListTime,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: DashboardColors.labelGrey,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: 4),
                      const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: DashboardColors.statCellBorder),
      ],
    );
  }
}

class _CanChip extends StatelessWidget {
  const _CanChip({required this.label, this.cool = false});

  final String label;
  final bool cool;

  @override
  Widget build(BuildContext context) {
    final color = cool ? DashboardColors.statGreen : DashboardColors.statBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

extension _DeliveryTimeFormat on DateTime {
  String get deliveryListTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(year, month, this.day);
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final t = '$h:${minute.toString().padLeft(2, '0')} $ampm';
    if (day == today) return 'Today, $t';
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == yesterday) return 'Yesterday, $t';
    return '${DateFormat('d MMM').format(this)}, $t';
  }
}

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: DashboardColors.screenGradient,
        child: child,
      ),
    );
  }
}
