import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
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
  int _normal = 0;
  int _cool = 0;
  final Map<String, int> _bottleQty = {};

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

  List<BottleDeliveryInput> _bottleInputs(List<Product> catalog) {
    final inputs = <BottleDeliveryInput>[];
    for (final product in catalog) {
      for (final variant in product.variants) {
        final key = '${product.id}|${variant.id}';
        final qty = _bottleQty[key] ?? 0;
        if (qty > 0) {
          inputs.add(
            BottleDeliveryInput(
              label: variant.label,
              quantity: qty,
              unitPrice: variant.price,
              productId: product.id,
            ),
          );
        }
      }
    }
    return inputs;
  }

  List<DeliveryPriceLine> _priceLines(WaterPlantRepository repo, List<Product> catalog) {
    final settings = repo.settings;
    final lines = <DeliveryPriceLine>[];
    if (_normal > 0) {
      lines.add(
        DeliveryPriceLine(
          name: 'Normal Cans',
          calc: '$_normal x ${settings.normalPrice}',
          amount: _normal * settings.normalPrice,
        ),
      );
    }
    if (_cool > 0) {
      lines.add(
        DeliveryPriceLine(
          name: 'Cool Cans',
          calc: '$_cool x ${settings.coolPrice}',
          amount: _cool * settings.coolPrice,
        ),
      );
    }
    for (final product in catalog) {
      for (final variant in product.variants) {
        final key = '${product.id}|${variant.id}';
        final qty = _bottleQty[key] ?? 0;
        if (qty > 0) {
          lines.add(
            DeliveryPriceLine(
              name: variant.label,
              calc: '$qty x ${variant.price}',
              amount: qty * variant.price,
            ),
          );
        }
      }
    }
    return lines;
  }

  double _total(List<DeliveryPriceLine> lines) =>
      lines.fold<double>(0, (sum, l) => sum + l.amount);

  bool _hasItems(List<Product> catalog) {
    if (_normal + _cool > 0) return true;
    return _bottleInputs(catalog).isNotEmpty;
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

        final bottleCatalog = repo.bottleCatalog;
        final priceLines = _priceLines(repo, bottleCatalog);
        final total = _total(priceLines);
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
                      const AddDeliverySectionTitle(
                        title: '20L Water Cans',
                        subtitle: 'Normal & cool refill cans',
                      ),
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
                      const AddDeliverySectionTitle(
                        title: 'Water Bottles',
                        subtitle: 'From your product catalog',
                      ),
                      AddDeliveryBottleCatalog(
                        products: bottleCatalog,
                        quantities: _bottleQty,
                        onChanged: (key, qty) => setState(() => _bottleQty[key] = qty),
                      ),
                      AddDeliveryPriceSection(lines: priceLines, total: total),
                    ],
                  ),
                ),
                AddDeliverySaveButton(
                  enabled: _hasItems(bottleCatalog),
                  onPressed: () {
                    final delivery = repo.addDelivery(
                      customerId: widget.customerId,
                      date: _date,
                      normalQty: _normal,
                      coolQty: _cool,
                      bottles: _bottleInputs(bottleCatalog),
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
