import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_detail_sheets.dart';
import 'package:sri_sai_ro_water/features/bills/widgets/monthly_summary_widgets.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Read-only month detail for contract customers (no admin actions).
class CustomerMonthReadonlyScreen extends StatefulWidget {
  const CustomerMonthReadonlyScreen({
    super.key,
    required this.customerId,
    this.shopId,
    this.initialMonth,
  });

  final String customerId;
  final String? shopId;
  final DateTime? initialMonth;

  @override
  State<CustomerMonthReadonlyScreen> createState() =>
      _CustomerMonthReadonlyScreenState();
}

class _CustomerMonthReadonlyScreenState extends State<CustomerMonthReadonlyScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialMonth;
    _month = initial != null
        ? DateTime(initial.year, initial.month)
        : DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Month details')),
            body: const Center(child: Text('Not found')),
          );
        }

        final stats = repo.monthlyStatsForCustomer(widget.customerId, _month);
        final balance = repo.customerBalance(widget.customerId);
        final deliveries =
            repo.deliveriesForCustomer(widget.customerId, month: _month);
        final payments =
            repo.paymentsForCustomer(widget.customerId, month: _month);
        final colorIndex =
            repo.customers.indexWhere((c) => c.id == widget.customerId);
        final shopId = widget.shopId ?? repo.shopIdForCustomer(widget.customerId);
        final shop = repo.shopById(shopId);

        return Scaffold(
          backgroundColor: MonthlySummaryColors.screenBg,
          body: MonthlySummaryScaffold(
            child: Column(
              children: [
                MonthlySummaryHeader(
                  onBack: () => context.pop(),
                  monthLabel: _month.monthYear,
                ),
                if (shop != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        shop.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CustomerColors.accent,
                        ),
                      ),
                    ),
                  ),
                MonthlySummaryCustomerBar(
                  customer: customer,
                  colorIndex: colorIndex >= 0 ? colorIndex : 0,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: CustomerPrimaryButton(
                          label: 'View full monthly bill (PDF layout)',
                          icon: Icons.description_outlined,
                          onPressed: () => context.push(
                            '${AppRoutes.customerMonthlyBill}?customerId=${widget.customerId}'
                            '&shopId=$shopId&year=${_month.year}&month=${_month.month}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      MonthlySummaryStatsCard(stats: stats),
                      MonthlySummaryAccountCard(stats: stats, balance: balance),
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
                        onViewAllPayments: () => showMonthlyPaymentsSheet(
                          context,
                          customer: customer,
                          month: _month,
                          payments: payments,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'This is a read-only view. Contact your shop to record '
                          'payments or change deliveries.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: CustomerColors.labelGrey,
                          ),
                        ),
                      ),
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
