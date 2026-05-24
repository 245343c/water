import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/reports_summary.dart';
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
  ReportsSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _applyPreset(ReportsPeriodPreset.thisMonth, notify: false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    final repo = context.read<WaterPlantRepository>();
    final summary = await repo.fetchReportsSummary(_start, _end);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
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
      _loadSummary();
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
      await _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final summary = _summary;
        final chartBuckets = summary == null
            ? <ReportsChartBucket>[]
            : reportsChartBuckets(summary.dailyBuckets, _start, _end);

        return Scaffold(
          backgroundColor: ReportsColors.screenBg,
          body: ReportsScaffold(
            child: Column(
              children: [
                ReportsHeader(onBack: () => context.pop()),
                Expanded(
                  child: _loading && summary == null
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
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
                            if (summary != null) ...[
                              ReportsHeroSummaryCard(
                                sales: summary.totalSales,
                                collected: summary.collected,
                                cans: summary.totalCans,
                              ),
                              ReportsKpiGrid(
                                totalCans: summary.totalCans,
                                normalCans: summary.normalCans,
                                coolCans: summary.coolCans,
                                totalSales: summary.totalSales,
                                collected: summary.collected,
                                activeCustomers: summary.activeCustomers,
                                pendingAmount: summary.pendingAmount,
                              ),
                              ReportsInsightStrip(
                                deliveryCount: summary.totalDeliveries,
                                avgCansPerDay: summary.avgCansPerDay,
                                collectionRate: summary.collectionRate,
                              ),
                              ReportsCansOverviewCard(buckets: chartBuckets),
                            ],
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
