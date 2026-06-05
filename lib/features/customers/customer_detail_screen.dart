import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/customer_delete_dialog.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_info_bar.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_detail_widgets.dart';
import 'package:sri_sai_ro_water/features/deliveries/record_empty_can_sheet.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = context.read<WaterPlantRepository>();
      await repo.loadCustomersForCurrentAdminFromFirestore();
      await repo.loadLedgerForCurrentShopFromFirestore();
    });
  }

  void _onCall(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.phone, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Number copied: $phone',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openMonthlySummary(DateTime month) {
    context.push(
      '/customers/${widget.customerId}/summary'
      '?year=${month.year}&month=${month.month}',
    );
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    WaterPlantRepository repo,
    String name,
  ) async {
    final confirmed = await confirmDeleteCustomer(context, customerName: name);
    if (!confirmed || !context.mounted) return;
    await repo.deleteCustomerFromCurrentAdminShop(widget.customerId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Customer deleted', style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go(AppRoutes.customers);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Details')),
            body: const Center(child: Text('Not found')),
          );
        }

        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);
        final monthly = repo.monthlyStatsForCustomer(
          widget.customerId,
          currentMonth,
        );
        final totalPending = repo.customerBalance(widget.customerId);
        final advanceCredit = repo.customerAdvanceCredit(widget.customerId);
        final previousPending = repo.previousBalanceForMonth(
          widget.customerId,
          currentMonth,
        );
        final canBalance = repo.customerCanBalance(widget.customerId);
        final idx = repo.customers.indexWhere((c) => c.id == widget.customerId);

        void openAddDelivery() => context.push(
              '/customers/${widget.customerId}/delivery',
            );

        return Scaffold(
          backgroundColor: CustomerDetailColors.screenBg,
          body: CustomerDetailScaffold(
            child: Column(
              children: [
                CustomerDetailHeader(
                  onBack: () => context.pop(),
                  onEdit: () =>
                      context.push('/customers/${widget.customerId}/edit'),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    children: [
                      CustomerInfoBar(
                        customer: customer,
                        colorIndex: idx >= 0 ? idx : 0,
                      ),
                      CustomerPendingCard(
                        totalPending: totalPending,
                        advanceCredit: advanceCredit,
                        previousPending: previousPending,
                        monthStats: monthly,
                      ),
                      CustomerCanBalanceCard(
                        balance: canBalance,
                        onRecordReturn: () async {
                          final saved = await showRecordEmptyCanReturnSheet(
                            context,
                            customerId: widget.customerId,
                          );
                          if (!context.mounted || saved != true) return;
                          final name = customer.name;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Empty return saved for $name',
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF0D9488),
                            ),
                          );
                        },
                      ),
                      CustomerMonthlyOverviewSection(
                        statsForMonth: (m) => repo.monthlyStatsForCustomer(
                          widget.customerId,
                          m,
                        ),
                        onMonthTap: _openMonthlySummary,
                        year: now.year,
                        initialMonth: now.month,
                      ),
                      QuickActionsSection(
                        onRecordPayment: () => context.push(
                          '/customers/${widget.customerId}/payment',
                        ),
                        onViewBills: () => context.push(
                          '/customers/${widget.customerId}/bill',
                        ),
                        onCall: () => _onCall(customer.phone),
                      ),
                      DeleteCustomerSection(
                        onDelete: () =>
                            _deleteCustomer(context, repo, customer.name),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: CustomerAddDeliveryButton(onPressed: openAddDelivery),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
