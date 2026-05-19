import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/reports/widgets/reports_screen_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _start;
  late DateTime _end;
  ReportsPeriodPreset _preset = ReportsPeriodPreset.thisMonth;

  @override
  void initState() {
    super.initState();
    _applyPreset(ReportsPeriodPreset.thisMonth, notify: false);
  }

  void _applyPreset(ReportsPeriodPreset preset, {bool notify = true}) {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (preset) {
      case ReportsPeriodPreset.thisWeek:
        final weekday = now.weekday;
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        end = start.add(const Duration(days: 6));
      case ReportsPeriodPreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
      case ReportsPeriodPreset.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
      case ReportsPeriodPreset.custom:
        return;
    }

    if (notify) {
      setState(() {
        _preset = preset;
        _start = start;
        _end = end;
      });
    } else {
      _preset = preset;
      _start = start;
      _end = end;
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null) {
      setState(() {
        _preset = ReportsPeriodPreset.custom;
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final deliveries = repo.deliveriesInRange(_start, _end);
        final daily = repo.dailyCanTotals(_start, _end);
        final cans = deliveries.fold<int>(0, (s, d) => s + d.normalQty + d.coolQty);
        final normalCans = deliveries.fold<int>(0, (s, d) => s + d.normalQty);
        final coolCans = deliveries.fold<int>(0, (s, d) => s + d.coolQty);
        final sales = deliveries.fold<double>(0, (s, d) => s + d.totalAmount);
        final collected = repo.paymentsTotalInRange(_start, _end);
        final activeCustomers = repo.activeCustomersInRange(_start, _end);
        var pending = 0.0;
        for (final c in repo.customers) {
          pending += repo.customerBalance(c.id).clamp(0.0, double.infinity);
        }
        final daysInRange = _end.difference(_start).inDays + 1;
        final avgCansPerDay = daysInRange > 0 ? cans / daysInRange : 0.0;
        final chartBuckets = reportsChartBuckets(daily, _start, _end);

        return Scaffold(
          backgroundColor: ReportsColors.screenBg,
          body: ReportsScaffold(
            child: Column(
              children: [
                ReportsHeader(onBack: () => context.pop()),
                Expanded(
                  child: ListView(
                    children: [
                      ReportsPeriodChips(
                        selected: _preset,
                        onSelect: (p) {
                          if (p == ReportsPeriodPreset.custom) {
                            _pickRange();
                          } else {
                            _applyPreset(p);
                          }
                        },
                      ),
                      ReportsDateRangeBar(
                        start: _start,
                        end: _end,
                        onTap: _pickRange,
                      ),
                      ReportsHeroSummaryCard(
                        sales: sales,
                        collected: collected,
                        cans: cans,
                      ),
                      ReportsKpiGrid(
                        totalCans: cans,
                        normalCans: normalCans,
                        coolCans: coolCans,
                        totalSales: sales,
                        collected: collected,
                        activeCustomers: activeCustomers,
                        pendingAmount: pending,
                      ),
                      ReportsInsightStrip(
                        deliveryCount: deliveries.length,
                        avgCansPerDay: avgCansPerDay,
                        collectionRate: sales > 0 ? (collected / sales).clamp(0.0, 1.0) : 0,
                      ),
                      ReportsCansOverviewCard(buckets: chartBuckets),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
