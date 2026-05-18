import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/payments/widgets/payment_history_widgets.dart';

/// All payments for a customer (newest first).
class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Payment History')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final payments = repo.paymentsForCustomer(customerId);
        final total = payments.fold<double>(0, (s, p) => s + p.amount);
        final colorIndex = repo.customers.indexWhere((c) => c.id == customerId);

        return Scaffold(
          backgroundColor: PaymentHistoryColors.screenBg,
          body: PaymentHistoryScaffold(
            child: Column(
              children: [
                PaymentHistoryHeader(onBack: () => context.pop()),
                PaymentHistoryCustomerBar(
                  customer: customer,
                  colorIndex: colorIndex >= 0 ? colorIndex : 0,
                ),
                PaymentHistoryHeroCard(
                  totalPaid: total,
                  paymentCount: payments.length,
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      PaymentHistoryList(payments: payments),
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
