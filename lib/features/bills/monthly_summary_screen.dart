import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_detail_sheets.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_summary_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({
    super.key,
    required this.customerId,
    this.initialMonth,
  });

  final String customerId;
  final DateTime? initialMonth;

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialMonth;
    if (initial != null) {
      _month = DateTime(initial.year, initial.month);
    } else {
      _month = DateTime(now.year, now.month);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = context.read<WaterPlantRepository>();
      await repo.loadCustomersForCurrentAdminFromFirestore();
      await repo.loadLedgerForCurrentShopFromFirestore(month: _month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            backgroundColor: CustomersColors.screenBg,
            body: CustomersScaffold(
              usePageGradient: true,
              child: Column(
                children: [
                  MonthlySummaryHeader(onBack: () => context.pop()),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Customer not found',
                        style: GoogleFonts.poppins(
                          color: CustomersColors.labelGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = repo.monthlyStatsForCustomer(widget.customerId, _month);
        final balance = repo.customerBalance(widget.customerId);
        final deliveries = repo.deliveriesForCustomer(
          widget.customerId,
          month: _month,
        );
        final payments = repo.paymentsForCustomer(
          widget.customerId,
          month: _month,
        );
        final colorIndex = repo.customers.indexWhere(
          (c) => c.id == widget.customerId,
        );

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: MonthlySummaryScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MonthlySummaryHeader(
                  onBack: () => context.pop(),
                  monthLabel: _month.monthYear,
                ),
                Expanded(
                  child: CustomersListPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MonthlySummaryCustomerBar(
                          customer: customer,
                          colorIndex: colorIndex >= 0 ? colorIndex : 0,
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 8),
                            children: [
                              MonthlySummaryStatsCard(stats: stats),
                              MonthlySummaryAccountCard(
                                stats: stats,
                                balance: balance,
                              ),
                              MonthlyDeliveriesSection(
                                deliveries: deliveries,
                                onViewAll: () => showMonthlyDeliveriesSheet(
                                  context,
                                  customer: customer,
                                  month: _month,
                                  deliveries: deliveries,
                                ),
                              ),
                              MonthlyPaymentsSection(
                                payments: payments,
                                onViewAllPayments: () =>
                                    showMonthlyPaymentsSheet(
                                      context,
                                      customer: customer,
                                      month: _month,
                                      payments: payments,
                                    ),
                              ),
                              MonthlySummaryInfoBanner(month: _month),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                MonthlySummaryPdfButton(
                  onPressed: () => context.push(
                    '/customers/${widget.customerId}/bill'
                    '?year=${_month.year}&month=${_month.month}',
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
