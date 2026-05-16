import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class ReportsColors {
  static const Color screenBg = Color(0xFFF3F4F6);
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color statNavy = Color(0xFF1E3A8A);
  static const Color statRed = Color(0xFFDC2626);
  static const Color normalCan = Color(0xFF2563EB);
  static const Color coolCan = Color(0xFF16A34A);
  static const Color gridLine = Color(0xFFE5E7EB);
}

/// One bar bucket for the cans overview chart.
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

  static String count(int n) => _count.format(n);
  static String dateRange(DateTime start, DateTime end) =>
      '${_range.format(start)} - ${_range.format(end)}';
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
      child: child,
    );
  }
}

class ReportsHeader extends StatelessWidget {
  const ReportsHeader({super.key, required this.onBack});

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
              'Reports',
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ReportsColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ReportsFormat.dateRange(start, end),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: ReportsColors.titleNavy,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 20, color: ReportsColors.labelGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReportsStatsGrid extends StatelessWidget {
  const ReportsStatsGrid({
    super.key,
    required this.totalCans,
    required this.totalSales,
    required this.totalCustomers,
    required this.pendingAmount,
  });

  final int totalCans;
  final double totalSales;
  final int totalCustomers;
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
        childAspectRatio: 1.45,
        children: [
          _StatCard(
            label: 'Total Cans Delivered',
            value: ReportsFormat.count(totalCans),
            valueColor: ReportsColors.statGreen,
          ),
          _StatCard(
            label: 'Total Sales',
            value: CurrencyUtils.format(totalSales),
            valueColor: ReportsColors.statGreen,
          ),
          _StatCard(
            label: 'Total Customers',
            value: ReportsFormat.count(totalCustomers),
            valueColor: ReportsColors.statNavy,
          ),
          _StatCard(
            label: 'Pending Amount',
            value: CurrencyUtils.format(pendingAmount),
            valueColor: ReportsColors.statRed,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ReportsColors.labelGrey,
              height: 1.25,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
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

class ReportsCansOverviewCard extends StatelessWidget {
  const ReportsCansOverviewCard({super.key, required this.buckets});

  final List<ReportsChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        decoration: BoxDecoration(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cans Delivered Overview',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ReportsColors.titleNavy,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(color: ReportsColors.normalCan, label: 'Normal Cans'),
                const SizedBox(width: 18),
                _LegendDot(color: ReportsColors.coolCan, label: 'Cool Cans'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: buckets.isEmpty
                  ? Center(
                      child: Text(
                        'No deliveries in this period',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: ReportsColors.labelGrey,
                        ),
                      ),
                    )
                  : _ReportsCansLineChart(buckets: buckets),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: ReportsColors.labelGrey),
        ),
      ],
    );
  }
}

class _ReportsCansLineChart extends StatelessWidget {
  const _ReportsCansLineChart({required this.buckets});

  final List<ReportsChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.fold<int>(0, (m, b) {
      final peak = b.normal > b.cool ? b.normal : b.cool;
      return peak > m ? peak : m;
    });
    final chartMax = _reportsNiceMaxY(maxValue);
    final interval = chartMax / 5;

    final normalSpots = [
      for (var i = 0; i < buckets.length; i++) FlSpot(i.toDouble(), buckets[i].normal.toDouble()),
    ];
    final coolSpots = [
      for (var i = 0; i < buckets.length; i++) FlSpot(i.toDouble(), buckets[i].cool.toDouble()),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (buckets.length - 1).toDouble().clamp(0, double.infinity),
        minY: 0,
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: ReportsColors.gridLine,
            strokeWidth: 1,
          ),
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
                if (value < 0 || value > chartMax) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 10, color: ReportsColors.labelGrey),
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
                if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    buckets[i].label.dayMonth,
                    style: GoogleFonts.poppins(fontSize: 10, color: ReportsColors.labelGrey),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => ReportsColors.titleNavy,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((spot) {
              final i = spot.x.toInt();
              if (i < 0 || i >= buckets.length) return null;
              final isNormal = spot.bar.color == ReportsColors.normalCan;
              final label = isNormal ? 'Normal' : 'Cool';
              return LineTooltipItem(
                '$label: ${spot.y.toInt()}',
                GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: normalSpots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: ReportsColors.normalCan,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: ReportsColors.normalCan,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ReportsColors.normalCan.withValues(alpha: 0.18),
                  ReportsColors.normalCan.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          LineChartBarData(
            spots: coolSpots,
            isCurved: true,
            curveSmoothness: 0.22,
            color: ReportsColors.coolCan,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: ReportsColors.coolCan,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ReportsColors.coolCan.withValues(alpha: 0.16),
                  ReportsColors.coolCan.withValues(alpha: 0.02),
                ],
              ),
            ),
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

/// Buckets daily totals into at most [maxBuckets] groups for chart labels.
List<ReportsChartBucket> reportsChartBuckets(
  Map<DateTime, ({int normal, int cool})> daily,
  DateTime start,
  DateTime end, {
  int maxBuckets = 5,
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
    for (var d = cursor; !d.isAfter(endDay); d = d.add(const Duration(days: 1))) {
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
