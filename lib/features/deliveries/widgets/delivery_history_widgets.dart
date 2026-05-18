import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class DeliveryHistoryColors {
  static const Color titleNavy = Color(0xFF1E3A8A);
  static const Color valueNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color screenBg = Color(0xFFF3F4F6);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color whatsapp = Color(0xFF25D366);
}

class DeliveryHistoryHeader extends StatelessWidget {
  const DeliveryHistoryHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 4, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Delivery History',
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

class DeliveryHistoryCustomerBar extends StatelessWidget {
  const DeliveryHistoryCustomerBar({
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
                    color: DeliveryHistoryColors.titleNavy,
                  ),
                ),
                Text(
                  customer.phone,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: DeliveryHistoryColors.labelGrey,
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

class DeliveryHistoryStatsStrip extends StatelessWidget {
  const DeliveryHistoryStatsStrip({
    super.key,
    required this.deliveryCount,
    required this.totalAmount,
  });

  final int deliveryCount;
  final String totalAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.local_shipping_outlined,
              label: 'Deliveries',
              value: '$deliveryCount',
              color: DeliveryHistoryColors.statBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatChip(
              icon: Icons.payments_outlined,
              label: 'Total value',
              value: totalAmount,
              color: DeliveryHistoryColors.statGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DeliveryHistoryColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: DeliveryHistoryColors.labelGrey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
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

/// All deliveries grouped by month — fills available height.
class DeliveryHistoryGroupedList extends StatelessWidget {
  const DeliveryHistoryGroupedList({super.key, required this.deliveries});

  final List<Delivery> deliveries;

  Map<String, List<Delivery>> get _grouped {
    final map = <String, List<Delivery>>{};
    for (final d in deliveries) {
      final key = d.date.monthYear;
      map.putIfAbsent(key, () => []).add(d);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 56,
                color: DeliveryHistoryColors.labelGrey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No deliveries yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DeliveryHistoryColors.titleNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Deliveries will appear here after you add them.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: DeliveryHistoryColors.labelGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _grouped.entries.toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeliveryHistoryColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        physics: const BouncingScrollPhysics(),
        children: [
          for (final group in groups) ...[
            _MonthSectionHeader(
              label: group.key,
              count: group.value.length,
            ),
            for (var i = 0; i < group.value.length; i++)
              _DeliveryTimelineTile(
                delivery: group.value[i],
                isLastInGroup: i == group.value.length - 1,
              ),
          ],
        ],
      ),
    );
  }
}

class _MonthSectionHeader extends StatelessWidget {
  const _MonthSectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: DeliveryHistoryColors.statBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DeliveryHistoryColors.titleNavy,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: DeliveryHistoryColors.statBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryTimelineTile extends StatelessWidget {
  const _DeliveryTimelineTile({
    required this.delivery,
    required this.isLastInGroup,
  });

  final Delivery delivery;
  final bool isLastInGroup;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: DeliveryHistoryColors.statBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: DeliveryHistoryColors.statBlue.withValues(alpha: 0.35),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLastInGroup)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFBFDBFE),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DeliveryHistoryColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.date.dayMonth,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DeliveryHistoryColors.valueNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          delivery.itemsSummary,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: DeliveryHistoryColors.labelGrey,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyUtils.format(delivery.totalAmount),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: DeliveryHistoryColors.statBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryHistoryScaffold extends StatelessWidget {
  const DeliveryHistoryScaffold({super.key, required this.child});

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
