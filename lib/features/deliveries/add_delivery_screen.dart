import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/deliveries/widgets/add_delivery_widgets.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> {
  DateTime _date = DateTime.now();
  int _normal = 1;
  int _cool = 0;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final customer = repo.customerById(widget.customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Add Delivery')),
            body: const Center(child: Text('Not found')),
          );
        }

        final settings = repo.settings;
        final nSub = _normal * settings.normalPrice;
        final cSub = _cool * settings.coolPrice;
        final total = nSub + cSub;
        final colorIndex = repo.customers.indexWhere((c) => c.id == widget.customerId);

        return Scaffold(
          backgroundColor: Colors.white,
          body: AddDeliveryScaffold(
            child: Column(
              children: [
                AddDeliveryHeader(onBack: () => context.pop()),
                Expanded(
                  child: ListView(
                    children: [
                      AddDeliveryCustomerBar(
                        customer: customer,
                        colorIndex: colorIndex >= 0 ? colorIndex : 0,
                      ),
                      AddDeliveryDateRow(date: _date, onTap: _pickDate),
                      AddDeliveryCanStepper(
                        label: 'Normal Water Cans',
                        value: _normal,
                        onChanged: (v) => setState(() => _normal = v),
                      ),
                      AddDeliveryCanStepper(
                        label: 'Cool Water Cans',
                        value: _cool,
                        onChanged: (v) => setState(() => _cool = v),
                      ),
                      AddDeliveryPriceSection(
                        normalQty: _normal,
                        coolQty: _cool,
                        normalPrice: settings.normalPrice,
                        coolPrice: settings.coolPrice,
                        total: total,
                      ),
                    ],
                  ),
                ),
                AddDeliverySaveButton(
                  enabled: _normal + _cool > 0,
                  onPressed: () {
                    final delivery = repo.addDelivery(
                      customerId: widget.customerId,
                      date: _date,
                      normalQty: _normal,
                      coolQty: _cool,
                    );
                    context.pushReplacement(
                      '/customers/${widget.customerId}/delivery/success',
                      extra: delivery,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
