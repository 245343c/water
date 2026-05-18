import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/delivery_history_widgets.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Delivery History')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final deliveries = repo.deliveriesForCustomer(customerId);
        final totalAmount =
            deliveries.fold<double>(0, (s, d) => s + d.totalAmount);
        final colorIndex = repo.customers.indexWhere((c) => c.id == customerId);

        return Scaffold(
          backgroundColor: DeliveryHistoryColors.screenBg,
          body: DeliveryHistoryScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeliveryHistoryHeader(onBack: () => context.pop()),
                DeliveryHistoryCustomerBar(
                  customer: customer,
                  colorIndex: colorIndex >= 0 ? colorIndex : 0,
                ),
                DeliveryHistoryStatsStrip(
                  deliveryCount: deliveries.length,
                  totalAmount: CurrencyUtils.format(totalAmount),
                ),
                Expanded(
                  child: DeliveryHistoryGroupedList(deliveries: deliveries),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
