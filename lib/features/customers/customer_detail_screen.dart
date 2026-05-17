import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/customer_delete_dialog.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_detail_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});
  final String customerId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(current)) setState(() => _month = next);
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

  Future<void> _deleteCustomer(
      BuildContext context, WaterPlantRepository repo, String name) async {
    final confirmed = await confirmDeleteCustomer(context, customerName: name);
    if (!confirmed || !context.mounted) return;
    repo.deleteCustomer(widget.customerId);
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

        final monthly = repo.monthlyStatsForCustomer(widget.customerId, _month);
        final totalBalance = repo.customerBalance(widget.customerId).clamp(0.0, double.infinity);
        final idx = repo.customers.indexWhere((c) => c.id == widget.customerId);

        return Scaffold(
          backgroundColor: CustomerDetailColors.screenBg,
          body: CustomerDetailScaffold(
            child: Column(
              children: [
                CustomerDetailHeader(
                  onBack: () => context.pop(),
                  onEdit: () => context.push('/customers/${widget.customerId}/edit'),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      // ── Profile ─────────────────────────────────────────
                      CustomerProfileSection(customer: customer, colorIndex: idx >= 0 ? idx : 0),

                      // ── Balance Hero ────────────────────────────────────
                      CustomerBalanceHero(
                        totalBalance: totalBalance,
                        stats: monthly,
                        month: _month,
                      ),

                      // ── This Month Summary ──────────────────────────────
                      CustomerOverviewCard(
                        month: _month,
                        stats: monthly,
                        onViewAll: () => context.push('/customers/${widget.customerId}/summary'),
                        onPrevMonth: _prevMonth,
                        onNextMonth: _nextMonth,
                      ),

                      // ── Quick Actions ───────────────────────────────────
                      QuickActionsSection(
                        onAddDelivery: () => context.push('/customers/${widget.customerId}/delivery'),
                        onRecordPayment: () => context.push('/customers/${widget.customerId}/payment'),
                        onViewBills: () => context.push('/customers/${widget.customerId}/bill'),
                        onViewHistory: () => context.push('/customers/${widget.customerId}/history'),
                        onCall: () => _onCall(customer.phone),
                        customerPhone: customer.phone,
                      ),

                      // ── Delete ──────────────────────────────────────────
                      DeleteCustomerSection(
                        onDelete: () => _deleteCustomer(context, repo, customer.name),
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
