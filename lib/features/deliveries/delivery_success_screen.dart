import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/delivery_success_widgets.dart';

class DeliverySuccessScreen extends StatelessWidget {
  const DeliverySuccessScreen({
    super.key,
    required this.customerId,
    required this.delivery,
  });

  final String customerId;
  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(customerId);

        return Scaffold(
          backgroundColor: DeliverySuccessColors.bgMint,
          body: DeliverySuccessScaffold(
            child: DeliverySuccessView(
              customerName: customer?.name ?? '—',
              delivery: delivery,
              onContinue: () => context.pop(),
            ),
          ),
        );
      },
    );
  }
}
