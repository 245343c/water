import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

enum ReportsPeriodPreset { thisWeek, thisMonth, lastMonth, custom }

abstract final class ReportsColors {
  static const Color screenBg = AppColors.surface;
  static const Color titleNavy = AppColors.textPrimary;
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = AppColors.cardBorder;
  static const Color statGreen = Color(0xFF16A34A);
  static const Color statNavy = Color(0xFF1E3A8A);
  static const Color statRed = Color(0xFFDC2626);
  static const Color statAmber = Color(0xFFD97706);
  static const Color normalCan = Color(0xFF2563EB);
  static const Color coolCan = Color(0xFF16A34A);
  static const Color gridLine = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color heroStart = Color(0xFF1E3A8A);
  static const Color heroEnd = Color(0xFF2563EB);
}

abstract final class ReportsFormat {
  static final NumberFormat _count = NumberFormat('#,##,###', 'en_IN');
  static final DateFormat _range = DateFormat('d MMM yyyy');
  static final DateFormat _short = DateFormat('d MMM');

  static String count(int n) => _count.format(n);
  static String countDouble(double n) => _count.format(n);
  static String dateRange(DateTime start, DateTime end) =>
      '${_range.format(start)} – ${_range.format(end)}';
  static String shortDate(DateTime d) => _short.format(d);
  static String percent(double ratio) => '${(ratio * 100).round()}%';
}

class ReportsScaffold extends StatelessWidget {
  const ReportsScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: CustomersColors.screenGradient,
        child: PremiumResponsiveBody(
          maxWidth: 1180,
          horizontalPadding: 4,
          child: child,
        ),
      ),
    );
  }
}

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Sales report',
      subtitle: 'Deliveries and collections',
      onBack: onBack,
    );
  }
}

/// Simple month switch — This month or Last month only.
class ReportsSimpleMonthPicker extends StatelessWidget {
  const ReportsSimpleMonthPicker({
    super.key,
    required this.selected,
    required this.start,
    required this.end,
    required this.onThisMonth,
    required this.onLastMonth,
    required this.onPickDates,
  });

  final ReportsPeriodPreset selected;
  final DateTime start;
  final DateTime end;
  final VoidCallback onThisMonth;
  final VoidCallback onLastMonth;
  final VoidCallback onPickDates;

  @override
  Widget build(BuildContext context) {
    final isThisMonth = selected == ReportsPeriodPreset.thisMonth;
    final isLastMonth = selected == ReportsPeriodPreset.lastMonth;
    final isCustom = selected == ReportsPeriodPreset.custom;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: CustomersColors.whiteCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Which month?',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ReportsColors.titleNavy,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MonthChoice(
                    label: 'This month',
                    selected: isThisMonth,
                    onTap: onThisMonth,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MonthChoice(
                    label: 'Last month',
                    selected: isLastMonth,
                    onTap: onLastMonth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ReportsFormat.dateRange(start, end),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ReportsColors.labelGrey,
              ),
            ),
            if (isCustom)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Custom dates selected',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ReportsColors.heroEnd,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onPickDates,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Pick other dates',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ReportsColors.heroEnd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthChoice extends StatelessWidget {
  const _MonthChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ReportsColors.heroEnd : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : ReportsColors.titleNavy,
            ),
          ),
        ),
      ),
    );
  }
}

/// One clear summary — no extra KPI boxes.
class ReportsSimpleSummaryCard extends StatelessWidget {
  const ReportsSimpleSummaryCard({
    super.key,
    required this.sales,
    required this.collected,
    required this.cans,
  });

  final double sales;
  final double collected;
  final int cans;

  @override
  Widget build(BuildContext context) {
    final pending = (sales - collected).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: CustomersColors.whiteCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CurrencyUtils.format(sales),
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: ReportsColors.titleNavy,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Total sales in period',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: ReportsColors.labelGrey,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: ReportsColors.divider),
            const SizedBox(height: 16),
            Row(
              children: [
                _SummaryColumn(
                  label: 'Collected',
                  value: CurrencyUtils.format(collected),
                  color: ReportsColors.statGreen,
                ),
                _summaryDivider(),
                _SummaryColumn(
                  label: 'Pending',
                  value: CurrencyUtils.format(pending),
                  color: pending > 0
                      ? ReportsColors.statRed
                      : ReportsColors.titleNavy,
                ),
                _summaryDivider(),
                _SummaryColumn(
                  label: 'Cans',
                  value: ReportsFormat.count(cans),
                  color: ReportsColors.titleNavy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _summaryDivider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: ReportsColors.divider,
      );
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: ReportsColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsSimpleFootnote extends StatelessWidget {
  const ReportsSimpleFootnote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Text(
        'Numbers come from deliveries and payments recorded in this app.',
        style: GoogleFonts.poppins(
          fontSize: 11,
          height: 1.45,
          color: ReportsColors.labelGrey,
        ),
      ),
    );
  }
}

class ReportsPeriodChips extends StatelessWidget {
  const ReportsPeriodChips({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ReportsPeriodPreset selected;
  final ValueChanged<ReportsPeriodPreset> onSelect;

  static const _labels = {
    ReportsPeriodPreset.thisWeek: 'This week',
    ReportsPeriodPreset.thisMonth: 'This month',
    ReportsPeriodPreset.lastMonth: 'Last month',
    ReportsPeriodPreset.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReportsPeriodPreset.values.map((preset) {
            final isSelected = selected == preset;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  _labels[preset]!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : ReportsColors.titleNavy,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelect(preset),
                showCheckmark: false,
                selectedColor: ReportsColors.heroEnd,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? ReportsColors.heroEnd
                      : ReportsColors.cardBorder,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ReportsDateRangeBar extends StatelessWidget {
  const ReportsDateRangeBar({
    super.key,
    required this.start,
    required this.end,
    required this.onTap,
  });

  final DateTime start;
  final DateTime end;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: CustomersColors.whiteCard,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.date_range_rounded,
                    color: ReportsColors.heroEnd,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date range',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ReportsColors.labelGrey,
                        ),
                      ),
                      Text(
                        ReportsFormat.dateRange(start, end),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ReportsColors.titleNavy,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: ReportsColors.labelGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportsHeroSummaryCard extends StatelessWidget {
  const ReportsHeroSummaryCard({
    super.key,
    required this.sales,
    required this.collected,
    required this.cans,
  });

  final double sales;
  final double collected;
  final int cans;

  @override
  Widget build(BuildContext context) {
    final gap = (sales - collected).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: CustomersColors.whiteCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ReportsColors.heroEnd.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: ReportsColors.heroEnd,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Period performance',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ReportsColors.labelGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyUtils.format(sales),
              style: GoogleFonts.poppins(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: ReportsColors.titleNavy,
                height: 1,
              ),
            ),
            Text(
              'Delivery sales in range',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: ReportsColors.labelGrey,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: 'Collected',
                    value: CurrencyUtils.format(collected),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: ReportsColors.divider,
                ),
                Expanded(
                  child: _HeroMetric(
                    label: 'Outstanding',
                    value: CurrencyUtils.format(gap),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: ReportsColors.divider,
                ),
                Expanded(
                  child: _HeroMetric(
                    label: '20L cans',
                    value: ReportsFormat.count(cans),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ReportsColors.titleNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: ReportsColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsKpiGrid extends StatelessWidget {
  const ReportsKpiGrid({
    super.key,
    required this.normalCans,
    required this.coolCans,
    required this.catalogUnits,
    required this.activeCustomers,
  });

  final int normalCans;
  final int coolCans;
  final int catalogUnits;
  final int activeCustomers;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _KpiCard(
        icon: Icons.water_drop_outlined,
        iconColor: ReportsColors.normalCan,
        label: 'Normal cans',
        value: ReportsFormat.count(normalCans),
        valueColor: ReportsColors.statNavy,
      ),
      _KpiCard(
        icon: Icons.ac_unit_rounded,
        iconColor: ReportsColors.coolCan,
        label: 'Cool cans',
        value: ReportsFormat.count(coolCans),
        valueColor: ReportsColors.statGreen,
      ),
      if (catalogUnits > 0)
        _KpiCard(
          icon: Icons.inventory_2_outlined,
          iconColor: ReportsColors.statAmber,
          label: 'Catalog units',
          value: ReportsFormat.count(catalogUnits),
          valueColor: ReportsColors.statAmber,
        ),
      _KpiCard(
        icon: Icons.groups_rounded,
        iconColor: ReportsColors.heroEnd,
        label: 'Active customers',
        value: ReportsFormat.count(activeCustomers),
        valueColor: ReportsColors.titleNavy,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.05,
        children: tiles,
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueSize = 20,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: CustomersColors.whiteCard,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ReportsColors.labelGrey,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: valueSize,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                      height: 1,
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

/// Explains what is counted in this report vs full sales total.
class ReportsScopeNote extends StatelessWidget {
  const ReportsScopeNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Text(
        'Total sales above includes every delivery line. Can counts are normal & cool 20L only; '
        'catalog bottles show when recorded. Lorry and auto products are in sales, not can tiles.',
        style: GoogleFonts.poppins(
          fontSize: 11,
          height: 1.45,
          color: ReportsColors.labelGrey,
        ),
      ),
    );
  }
}

class ReportsInsightStrip extends StatelessWidget {
  const ReportsInsightStrip({
    super.key,
    required this.deliveryCount,
    required this.avgCansPerDay,
    required this.collectionRate,
  });

  final int deliveryCount;
  final double avgCansPerDay;
  final double collectionRate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: CustomersColors.whiteCard,
        child: Row(
          children: [
            _InsightCell(
              icon: Icons.local_shipping_outlined,
              label: 'Trips',
              value: ReportsFormat.count(deliveryCount),
            ),
            _verticalDivider(),
            _InsightCell(
              icon: Icons.speed_rounded,
              label: 'Avg cans/day',
              value: ReportsFormat.countDouble(avgCansPerDay),
            ),
            _verticalDivider(),
            _InsightCell(
              icon: Icons.pie_chart_outline_rounded,
              label: 'Collection',
              value: ReportsFormat.percent(collectionRate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() => Container(
    width: 1,
    height: 40,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: ReportsColors.cardBorder,
  );
}

class _InsightCell extends StatelessWidget {
  const _InsightCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: ReportsColors.heroEnd),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ReportsColors.titleNavy,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: ReportsColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

