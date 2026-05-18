import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/data/models/dashboard_action_item.dart';
import 'package:sri_sai_ro_water/features/dashboard/widgets/dashboard_home_widgets.dart';

class DashboardActionCenter extends StatelessWidget {
  const DashboardActionCenter({
    super.key,
    required this.items,
    required this.onItemTap,
    this.onViewCustomers,
    this.previewCount = 4,
  });

  final List<DashboardActionItem> items;
  final void Function(DashboardActionItem item) onItemTap;
  final VoidCallback? onViewCustomers;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final preview = items.take(previewCount).toList();
    final hasMore = items.length > previewCount;

    return Container(
      decoration: DashboardColors.whiteCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFFEA580C)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Action Center',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.cardTitle,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DashboardColors.statRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${items.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.statRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Needs your attention',
            style: GoogleFonts.poppins(fontSize: 11, color: DashboardColors.labelGrey),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _AllClearState()
          else
            ...List.generate(preview.length, (i) {
              return _ActionRow(
                item: preview[i],
                onTap: () => onItemTap(preview[i]),
                showDivider: i < preview.length - 1,
              );
            }),
          if (hasMore && onViewCustomers != null) ...[
            const SizedBox(height: 6),
            Material(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onViewCustomers,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'All customers',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DashboardColors.linkBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: DashboardColors.linkBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else if (items.isNotEmpty && onViewCustomers != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewCustomers,
                child: Text(
                  'View all customers',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DashboardColors.linkBlue,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AllClearState extends StatelessWidget {
  const _AllClearState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DashboardColors.statGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: DashboardColors.statGreen, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All clear',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Nothing needs attention right now',
                  style: GoogleFonts.poppins(fontSize: 12, color: DashboardColors.labelGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.item,
    required this.onTap,
    required this.showDivider,
  });

  final DashboardActionItem item;
  final VoidCallback onTap;
  final bool showDivider;

  static ({Color accent, Color bg, IconData icon}) _style(DashboardActionKind kind) {
    return switch (kind) {
      DashboardActionKind.overdue => (
          accent: DashboardColors.statRed,
          bg: const Color(0xFFFEF2F2),
          icon: Icons.warning_amber_rounded,
        ),
      DashboardActionKind.pendingPayment => (
          accent: const Color(0xFFEA580C),
          bg: const Color(0xFFFFF7ED),
          icon: Icons.payments_outlined,
        ),
      DashboardActionKind.noDeliveryToday => (
          accent: DashboardColors.statBlue,
          bg: const Color(0xFFEFF6FF),
          icon: Icons.local_shipping_outlined,
        ),
      DashboardActionKind.inactive => (
          accent: DashboardColors.statPurple,
          bg: const Color(0xFFF5F3FF),
          icon: Icons.schedule_rounded,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _style(item.kind);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 44,
                    decoration: BoxDecoration(
                      color: style.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(style.icon, color: style.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.customerName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            height: 1.3,
                            color: DashboardColors.labelGrey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: style.accent.withValues(alpha: 0.6)),
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
