import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/customer_delete_dialog.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_detail_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _deleteCustomer(BuildContext context, WaterPlantRepository repo, String name) async {
    final confirmed = await confirmDeleteCustomer(context, customerName: name);
    if (!confirmed || !context.mounted) return;
    repo.deleteCustomer(customerId);
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
        final customer = repo.customerById(customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer Details')),
            body: const Center(child: Text('Not found')),
          );
        }

        final month = DateTime.now();
        final monthly = repo.monthlyStatsForCustomer(customerId, month);
        final recent = repo.deliveriesForCustomer(customerId).take(3).toList();
        final idx = repo.customers.indexWhere((c) => c.id == customerId);

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomerDetailScaffold(
            child: Column(
              children: [
                CustomerDetailHeader(
                  onBack: () => context.pop(),
                  onEdit: () => context.push('/customers/$customerId/edit'),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      CustomerProfileSection(customer: customer, colorIndex: idx),
                      const SizedBox(height: 8),
                      CustomerOverviewCard(
                        month: month,
                        stats: monthly,
                        onViewAll: () => context.push('/customers/$customerId/summary'),
                      ),
                      QuickActionsSection(
                        onAddDelivery: () => context.push('/customers/$customerId/delivery'),
                        onViewHistory: () => context.push('/customers/$customerId/history'),
                        onViewBills: () => context.push('/customers/$customerId/bill'),
                        onRecordPayment: () => context.push('/customers/$customerId/payment'),
                      ),
                      RecentDeliveriesCard(
                        deliveries: recent,
                        onViewAll: () => context.push('/customers/$customerId/history'),
                        onItemTap: (_) => context.push('/customers/$customerId/history'),
                      ),
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
