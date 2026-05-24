import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
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
  static const Color heroStart = Color(0xFF1E3A8A);
  static const Color heroEnd = Color(0xFF2563EB);
}

class ReportsChartBucket {
  const ReportsChartBucket({
    required this.label,
    required this.normal,
    required this.cool,
  });

  final DateTime label;
  final int normal;
  final int cool;

  int get total => normal + cool;
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
      child: PremiumResponsiveBody(maxWidth: 1180, child: child),
    );
  }
}

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Reports',
      subtitle: 'Sales, deliveries and collections',
      onBack: onBack,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: _reportsCardDecoration,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ReportsColors.heroStart, ReportsColors.heroEnd],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ReportsColors.heroEnd.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Period performance',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              CurrencyUtils.format(sales),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            Text(
              'Delivery sales in range',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16),
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
                  color: Colors.white.withValues(alpha: 0.25),
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
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _HeroMetric(
                    label: 'Cans',
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.8),
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
    required this.totalCans,
    required this.normalCans,
    required this.coolCans,
    required this.totalSales,
    required this.collected,
    required this.activeCustomers,
    required this.pendingAmount,
  });

  final int totalCans;
  final int normalCans;
  final int coolCans;
  final double totalSales;
  final double collected;
  final int activeCustomers;
  final double pendingAmount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
        children: [
          _KpiCard(
            icon: Icons.local_drink_rounded,
            iconColor: ReportsColors.normalCan,
            label: 'Total cans',
            value: ReportsFormat.count(totalCans),
            valueColor: ReportsColors.statNavy,
          ),
          _KpiCard(
            icon: Icons.payments_rounded,
            iconColor: ReportsColors.statGreen,
            label: 'Collected',
            value: CurrencyUtils.format(collected),
            valueColor: ReportsColors.statGreen,
          ),
          _KpiCard(
            icon: Icons.water_drop_outlined,
            iconColor: ReportsColors.normalCan,
            label: 'Normal · Cool',
            value:
                '${ReportsFormat.count(normalCans)} · ${ReportsFormat.count(coolCans)}',
            valueColor: ReportsColors.titleNavy,
            valueSize: 16,
          ),
          _KpiCard(
            icon: Icons.groups_rounded,
            iconColor: ReportsColors.statAmber,
            label: 'Active customers',
            value: ReportsFormat.count(activeCustomers),
            valueColor: ReportsColors.statAmber,
          ),
          _KpiCard(
            icon: Icons.receipt_long_rounded,
            iconColor: ReportsColors.statGreen,
            label: 'Delivery sales',
            value: CurrencyUtils.format(totalSales),
            valueColor: ReportsColors.statGreen,
          ),
          _KpiCard(
            icon: Icons.warning_amber_rounded,
            iconColor: ReportsColors.statRed,
            label: 'All-time pending',
            value: CurrencyUtils.format(pendingAmount),
            valueColor: ReportsColors.statRed,
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: _reportsCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ReportsColors.labelGrey,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _reportsCardDecoration,
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

class ReportsCansOverviewCard extends StatelessWidget {
  const ReportsCansOverviewCard({super.key, required this.buckets});

  final List<ReportsChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        decoration: _reportsCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cans delivered',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ReportsColors.titleNavy,
                    ),
                  ),
                ),
                _LegendDot(color: ReportsColors.normalCan, label: 'Normal'),
                const SizedBox(width: 12),
                _LegendDot(color: ReportsColors.coolCan, label: 'Cool'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 230,
              child: buckets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 40,
                            color: ReportsColors.labelGrey.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No deliveries in this period',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: ReportsColors.labelGrey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _ReportsGroupedBarChart(buckets: buckets),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: ReportsColors.labelGrey,
          ),
        ),
      ],
    );
  }
}

class _ReportsGroupedBarChart extends StatelessWidget {
  const _ReportsGroupedBarChart({required this.buckets});

  final List<ReportsChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.fold<int>(0, (m, b) {
      final peak = b.normal > b.cool ? b.normal : b.cool;
      return peak > m ? peak : m;
    });
    final chartMax = _reportsNiceMaxY(maxValue);
    final interval = chartMax / 4;

    return BarChart(
      BarChartData(
        maxY: chartMax,
        minY: 0,
        groupsSpace: 14,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: ReportsColors.gridLine, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value > chartMax) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: ReportsColors.labelGrey,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[i].label.dayMonth,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: ReportsColors.labelGrey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => ReportsColors.titleNavy,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bucket = buckets[group.x.toInt()];
              final label = rodIndex == 0 ? 'Normal' : 'Cool';
              final qty = rodIndex == 0 ? bucket.normal : bucket.cool;
              return BarTooltipItem(
                '$label: $qty',
                GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < buckets.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: buckets[i].normal.toDouble(),
                  color: ReportsColors.normalCan,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: buckets[i].cool.toDouble(),
                  color: ReportsColors.coolCan,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

double _reportsNiceMaxY(int maxValue) {
  if (maxValue <= 0) return 100;
  const step = 20.0;
  final raw = ((maxValue / step).ceil() * step).toDouble();
  return raw < 100 ? 100 : raw;
}

List<ReportsChartBucket> reportsChartBuckets(
  Map<DateTime, ({int normal, int cool})> daily,
  DateTime start,
  DateTime end, {
  int maxBuckets = 7,
}) {
  if (daily.isEmpty) return [];

  final days = daily.keys.toList()..sort();
  if (days.length <= maxBuckets) {
    return days
        .map(
          (d) => ReportsChartBucket(
            label: d,
            normal: daily[d]!.normal,
            cool: daily[d]!.cool,
          ),
        )
        .toList();
  }

  final rangeStart = DateTime(start.year, start.month, start.day);
  final rangeEnd = DateTime(end.year, end.month, end.day);
  final totalDays = rangeEnd.difference(rangeStart).inDays + 1;
  final bucketSize = (totalDays / maxBuckets).ceil().clamp(1, totalDays);
  final buckets = <ReportsChartBucket>[];

  var cursor = rangeStart;
  while (!cursor.isAfter(rangeEnd) && buckets.length < maxBuckets) {
    final bucketEnd = cursor.add(Duration(days: bucketSize - 1));
    final endDay = bucketEnd.isAfter(rangeEnd) ? rangeEnd : bucketEnd;
    var normal = 0;
    var cool = 0;
    for (
      var d = cursor;
      !d.isAfter(endDay);
      d = d.add(const Duration(days: 1))
    ) {
      final key = DateTime(d.year, d.month, d.day);
      final data = daily[key];
      if (data != null) {
        normal += data.normal;
        cool += data.cool;
      }
    }
    buckets.add(ReportsChartBucket(label: cursor, normal: normal, cool: cool));
    cursor = endDay.add(const Duration(days: 1));
  }

  return buckets;
}

BoxDecoration get _reportsCardDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: ReportsColors.cardBorder),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);
