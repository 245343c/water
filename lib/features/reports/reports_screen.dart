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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
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
        final sales = deliveries.fold<double>(0, (s, d) => s + d.totalAmount);
        var pending = 0.0;
        for (final c in repo.customers) {
          pending += repo.customerBalance(c.id).clamp(0.0, double.infinity);
        }
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
                      ReportsDateRangeBar(
                        start: _start,
                        end: _end,
                        onTap: _pickRange,
                      ),
                      ReportsStatsGrid(
                        totalCans: cans,
                        totalSales: sales,
                        totalCustomers: repo.customers.length,
                        pendingAmount: pending,
                      ),
                      ReportsCansOverviewCard(buckets: chartBuckets),
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
