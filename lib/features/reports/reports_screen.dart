import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/widgets/month_year_wheel_picker.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/dashboard/widgets/dashboard_home_widgets.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = context.read<WaterPlantRepository>();
      await repo.loadCustomersForCurrentAdminFromFirestore();
      await repo.loadLedgerForCurrentShopFromFirestore(
        start: _start,
        end: _end,
      );
    });
  }

  Future<void> _loadSelectedRange() async {
    await context
        .read<WaterPlantRepository>()
        .loadLedgerForCurrentShopFromFirestore(start: _start, end: _end);
  }

  Future<void> _applyPreset(
    ReportsPeriodPreset preset, {
    bool notify = true,
  }) async {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (preset) {
      case ReportsPeriodPreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
      case ReportsPeriodPreset.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
      case ReportsPeriodPreset.thisWeek:
      case ReportsPeriodPreset.pickedMonth:
      case ReportsPeriodPreset.custom:
        return;
    }

    if (notify) {
      setState(() {
        _preset = preset;
        _start = start;
        _end = end;
      });
      await _loadSelectedRange();
    } else {
      _preset = preset;
      _start = start;
      _end = end;
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearWheelPicker(
      context,
      initial: DateTime(_start.year, _start.month),
    );
    if (picked == null || !mounted) return;

    final start = DateTime(picked.year, picked.month, 1);
    final end = DateTime(picked.year, picked.month + 1, 0);
    setState(() {
      _preset = ReportsPeriodPreset.pickedMonth;
      _start = start;
      _end = end;
    });
    await _loadSelectedRange();
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
      await _loadSelectedRange();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final deliveries = repo.deliveriesInRange(_start, _end);
        final cans = deliveries.fold<int>(
          0,
          (s, d) => s + d.normalQty + d.coolQty,
        );
        final sales = deliveries.fold<double>(0, (s, d) => s + d.totalAmount);
        final collected = repo.paymentsTotalInRange(_start, _end);
        final productMix = repo.productBreakdownInRange(_start, _end);

        return Scaffold(
          backgroundColor: ReportsColors.screenBg,
          body: ReportsScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ReportsHeader(onBack: () => context.pop()),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        ReportsSimpleMonthPicker(
                          selected: _preset,
                          start: _start,
                          end: _end,
                          onThisMonth: () =>
                              _applyPreset(ReportsPeriodPreset.thisMonth),
                          onLastMonth: () =>
                              _applyPreset(ReportsPeriodPreset.lastMonth),
                          onPickMonth: _pickMonth,
                          onPickDates: _pickRange,
                        ),
                        ReportsSimpleSummaryCard(
                          sales: sales,
                          collected: collected,
                          cans: cans,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                          child: ProductMixBreakdownPanel(
                            title: 'Sales by product type',
                            rows: productMix,
                            totalLabel: 'Total sales',
                            totalAmount: CurrencyUtils.format(sales),
                          ),
                        ),
                        const ReportsSimpleFootnote(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
