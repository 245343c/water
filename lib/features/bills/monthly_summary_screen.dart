import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_summary_widgets.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() => setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    final now = DateTime.now();
    if (next.year > now.year || (next.year == now.year && next.month > now.month)) return;
    setState(() => _month = next);
  }

  bool get _canGoNext {
    final next = DateTime(_month.year, _month.month + 1);
    final now = DateTime.now();
    return !(next.year > now.year || (next.year == now.year && next.month > now.month));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Monthly Summary')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final stats = repo.monthlyStatsForCustomer(widget.customerId, _month);
        final balance = repo.customerBalance(widget.customerId);
        final deliveries = repo.deliveriesForCustomer(widget.customerId, month: _month);
        final payments = repo.paymentsForCustomer(widget.customerId, month: _month);
        final colorIndex = repo.customers.indexWhere((c) => c.id == widget.customerId);

        return Scaffold(
          backgroundColor: MonthlySummaryColors.screenBg,
          body: MonthlySummaryScaffold(
            child: Column(
              children: [
                MonthlySummaryHeader(onBack: () => context.pop()),
                MonthlySummaryCustomerBar(
                  customer: customer,
                  colorIndex: colorIndex >= 0 ? colorIndex : 0,
                ),
                MonthlySummaryMonthNav(
                  month: _month,
                  onPrev: _prevMonth,
                  onNext: _nextMonth,
                  canGoNext: _canGoNext,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      MonthlySummaryStatsCard(stats: stats),
                      MonthlySummaryAccountCard(stats: stats, balance: balance),
                      MonthlyDeliveriesSection(
                        deliveries: deliveries,
                        onViewAll: () => context.push('/customers/${widget.customerId}/history'),
                      ),
                      MonthlyPaymentsSection(
                        payments: payments,
                        onViewAllPayments: () => context.push('/customers/${widget.customerId}/payments'),
                      ),
                      MonthlySummaryInfoBanner(month: _month),
                    ],
                  ),
                ),
                MonthlySummaryPdfButton(
                  onPressed: () => context.push('/customers/${widget.customerId}/bill'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
