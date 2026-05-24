import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/core/widgets/app_image.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';

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
      BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );
}

// ─── Greeting helpers ────────────────────────────────────────────────────────

String _greetingText() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  if (h >= 17 && h < 21) return 'Good evening';
  return 'Good night';
}

// ─── Dashboard header with greeting + admin avatar ───────────────────────────

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    required this.ownerName,
    this.adminImagePath,
    this.onAdminTap,
    this.onNotificationsTap,
    this.notificationCount = 0,
  });

  final String title;
  final String ownerName;
  final String? adminImagePath;
  final VoidCallback? onAdminTap;
  final VoidCallback? onNotificationsTap;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingText();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $ownerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onNotificationsTap != null) ...[
            IconButton(
              onPressed: onNotificationsTap,
              icon: Badge(
                isLabelVisible: notificationCount > 0,
                label: Text('$notificationCount'),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),

          // Admin avatar — large enough to tap and see photo clearly
          GestureDetector(
            onTap: onAdminTap,
            child: Stack(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.70),
                      width: 2.5,
                    ),
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.75),
                  ),
                  child: ClipOval(
                    child: adminImagePath != null
                        ? AppImage(path: adminImagePath, width: 66, height: 66)
                        : const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),
                // Camera badge
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 12,
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.local_shipping_rounded,
                iconBg: const Color(0xFF1A73E8),
                label: 'Add Delivery',
                onTap: onAddDelivery,
                isFirst: true,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: DashboardColors.statCellBorder,
            ),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.person_add_alt_1_rounded,
                iconBg: DashboardColors.statGreen,
                label: 'Add Customer',
                onTap: onAddCustomer,
                isFirst: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardOwnerSnapshot extends StatelessWidget {
  const DashboardOwnerSnapshot({
    super.key,
    required this.todayDeliveries,
    required this.todayUnits,
    required this.pendingRequests,
    required this.onOrdersTap,
  });

  final int todayDeliveries;
  final int todayUnits;
  final int pendingRequests;
  final VoidCallback onOrdersTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardColors.whiteCard,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DashboardColors.linkBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.dashboard_customize_rounded,
                  color: DashboardColors.linkBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: DashboardColors.cardTitle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 620;
              final cards = [
                _OwnerMetricTile(
                  label: 'Today deliveries',
                  value: '$todayDeliveries',
                  helper: 'Saved today',
                  color: DashboardColors.statTeal,
                  icon: Icons.local_shipping_rounded,
                ),
                _OwnerMetricTile(
                  label: 'Cans delivered',
                  value: '$todayUnits',
                  helper: 'Normal, cool and bottles',
                  color: DashboardColors.statBlue,
                  icon: Icons.water_drop_rounded,
                ),
                _OwnerMetricTile(
                  label: 'Pending requests',
                  value: '$pendingRequests',
                  helper: 'Need admin action',
                  color: DashboardColors.statRed,
                  icon: Icons.receipt_long_rounded,
                  onTap: onOrdersTap,
                ),
              ];

              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i != cards.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OwnerMetricTile extends StatelessWidget {
  const _OwnerMetricTile({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final String helper;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      helper,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: DashboardColors.labelGrey,
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

class DashboardPendingRequestsCard extends StatelessWidget {
  const DashboardPendingRequestsCard({
    super.key,
    required this.requests,
    required this.onOpenOrders,
    required this.customerNameFor,
  });

  final List<DashboardPendingRequest> requests;
  final VoidCallback onOpenOrders;
  final String Function(String customerId) customerNameFor;

  @override
  Widget build(BuildContext context) {
    final preview = requests.take(3).toList();

    return Container(
      decoration: DashboardColors.whiteCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardCardHeader(
            icon: Icons.receipt_long_rounded,
            iconColor: DashboardColors.statRed,
            title: 'Pending requests',
            actionLabel: requests.isEmpty ? null : 'View all',
            onAction: requests.isEmpty ? null : onOpenOrders,
          ),
          const SizedBox(height: 10),
          if (preview.isEmpty)
            const _DashboardClearLine(
              icon: Icons.check_circle_rounded,
              title: 'No customer requests waiting',
              subtitle: 'New customer app requests will appear here.',
            )
          else
            ...List.generate(preview.length, (i) {
              final request = preview[i];
              return _PendingRequestRow(
                request: request,
                customerName: customerNameFor(request.customerId),
                onTap: onOpenOrders,
                showDivider: i < preview.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class DashboardPendingRequest {
  const DashboardPendingRequest({
    required this.customerId,
    required this.summary,
    required this.createdAt,
  });

  final String customerId;
  final String summary;
  final DateTime createdAt;
}

class _PendingRequestRow extends StatelessWidget {
  const _PendingRequestRow({
    required this.request,
    required this.customerName,
    required this.onTap,
    required this.showDivider,
  });

  final DashboardPendingRequest request;
  final String customerName;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          request.summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: DashboardColors.labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        request.createdAt.timeLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: DashboardColors.labelGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardColors.linkBlue.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'View',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: DashboardColors.linkBlue,
                          ),
                        ),
                      ),
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

class DashboardDriverActivityCard extends StatelessWidget {
  const DashboardDriverActivityCard({
    super.key,
    required this.activities,
    required this.activeDrivers,
    required this.totalDrivers,
    required this.onManageDrivers,
  });

  final List<DashboardDriverActivity> activities;
  final int activeDrivers;
  final int totalDrivers;
  final VoidCallback onManageDrivers;

  @override
  Widget build(BuildContext context) {
    final preview = activities.take(3).toList();

    return Container(
      decoration: DashboardColors.whiteCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardCardHeader(
            icon: Icons.badge_rounded,
            iconColor: DashboardColors.statTeal,
            title: 'Driver activity',
            actionLabel: 'Manage',
            onAction: onManageDrivers,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: DashboardColors.statTeal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$activeDrivers active / $totalDrivers total',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: DashboardColors.statTeal,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (preview.isEmpty)
            const _DashboardClearLine(
              icon: Icons.local_shipping_outlined,
              title: 'No driver deliveries today',
              subtitle: 'Accepted tasks and saved deliveries will show here.',
            )
          else
            ...List.generate(preview.length, (i) {
              final activity = preview[i];
              return _DriverActivityRow(
                activity: activity,
                showDivider: i < preview.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class DashboardDriverActivity {
  const DashboardDriverActivity({
    required this.name,
    required this.deliveries,
    required this.units,
    required this.active,
  });

  final String name;
  final int deliveries;
  final int units;
  final bool active;
}

class _DriverActivityRow extends StatelessWidget {
  const _DriverActivityRow({required this.activity, required this.showDivider});

  final DashboardDriverActivity activity;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = activity.active
        ? DashboardColors.statTeal
        : DashboardColors.labelGrey;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    activity.name.isEmpty
                        ? '?'
                        : activity.name[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activity.active ? 'Active' : 'Inactive',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: DashboardColors.labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${activity.deliveries} trips',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    Text(
                      '${activity.units} cans',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: DashboardColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: DashboardColors.statCellBorder),
      ],
    );
  }
}

class DashboardOperationsGrid extends StatelessWidget {
  const DashboardOperationsGrid({
    super.key,
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 14),
              Expanded(child: right),
            ],
          );
        }
        return Column(children: [left, const SizedBox(height: 14), right]);
      },
    );
  }
}

class _DashboardCardHeader extends StatelessWidget {
  const _DashboardCardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DashboardColors.cardTitle,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: DashboardColors.linkBlue,
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardClearLine extends StatelessWidget {
  const _DashboardClearLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DashboardColors.statGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DashboardColors.statGreen, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: DashboardColors.labelGrey,
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

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.onTap,
    required this.isFirst,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: Radius.circular(isFirst ? 20 : 0),
      right: Radius.circular(isFirst ? 0 : 20),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon square with solid bg
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: DashboardColors.labelGrey,
              ),
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
    required this.totalUnits,
    required this.activeCustomers,
    required this.paidThisMonth,
    required this.pendingAmount,
  });

  final String totalSales;
  final String totalDeliveries;
  final String totalUnits;
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
          // ── Title + month chip ─────────────────────────────────────────
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

          // ── Total Sales hero (teal gradient) ──────────────────────────
          _SalesHero(
            totalSales: data.totalSales,
            deliveries: data.totalDeliveries,
            units: data.totalUnits,
          ),
          const SizedBox(height: 10),

          // ── Paid / Pending chips ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MoneyChip(
                  label: 'Paid',
                  value: data.paidThisMonth,
                  color: DashboardColors.statGreen,
                  bg: const Color(0xFFECFDF5),
                  icon: Icons.check_circle_rounded,
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

          // ── Deliveries / Units / Customers compact row ─────────────────
          Row(
            children: [
              Expanded(
                child: _CompactMetric(
                  value: data.totalDeliveries,
                  label: 'Deliveries',
                  color: DashboardColors.statBlue,
                  icon: Icons.local_shipping_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactMetric(
                  value: data.totalUnits,
                  label: 'Units',
                  color: DashboardColors.statTeal,
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

// ─── Total Sales hero banner ──────────────────────────────────────────────────

class _SalesHero extends StatelessWidget {
  const _SalesHero({
    required this.totalSales,
    required this.deliveries,
    required this.units,
  });

  final String totalSales;
  final String deliveries;
  final String units;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0369A1), Color(0xFF06B6D4)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      child: Row(
        children: [
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Sales',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
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
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$deliveries deliveries  •  $units units',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
          // Water drop illustration
          Icon(
            Icons.water_drop_rounded,
            size: 72,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

// ─── Paid / Pending chip ──────────────────────────────────────────────────────

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
          Icon(icon, size: 20, color: color),
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

// ─── Compact metric tile ──────────────────────────────────────────────────────

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
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF6B7280),
              ),
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
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
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
        child: PremiumResponsiveBody(maxWidth: 1180, child: child),
      ),
    );
  }
}
