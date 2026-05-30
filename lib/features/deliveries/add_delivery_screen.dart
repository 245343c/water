import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
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
  bool _saving = false;

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

  List<BottleDeliveryInput> _bottleInputs(Customer customer, WaterPlantRepository repo, List<Product> catalog) {
    final inputs = <BottleDeliveryInput>[];
    for (final product in catalog) {
      for (final variant in product.variants) {
        final key = '${product.id}|${variant.id}';
        final qty = _bottleQty[key] ?? 0;
        if (qty > 0) {
          final unitPrice = repo.customerUnitPrice(
            customer,
            productId: product.id,
            variantId: variant.id,
          );
          inputs.add(
            BottleDeliveryInput(
              label: variant.label,
              quantity: qty,
              unitPrice: unitPrice,
              productId: product.id,
            ),
          );
        }
      }
    }
    return inputs;
  }

  List<DeliveryPriceLine> _priceLines(
    WaterPlantRepository repo,
    Customer customer,
    List<Product> catalog,
  ) {
    final lines = <DeliveryPriceLine>[];
    if (_normal > 0) {
      final unit = repo.customerUnitPrice(
        customer,
        productId: CustomerPricingKeys.canProductId,
        variantId: CustomerPricingKeys.normalVariantId,
      );
      lines.add(
        DeliveryPriceLine(
          name: 'Normal Cans',
          calc: '$_normal x $unit',
          amount: _normal * unit,
        ),
      );
    }
    if (_cool > 0) {
      final unit = repo.customerUnitPrice(
        customer,
        productId: CustomerPricingKeys.canProductId,
        variantId: CustomerPricingKeys.coolVariantId,
      );
      lines.add(
        DeliveryPriceLine(
          name: 'Cool Cans',
          calc: '$_cool x $unit',
          amount: _cool * unit,
        ),
      );
    }
    for (final product in catalog) {
      for (final variant in product.variants) {
        final key = '${product.id}|${variant.id}';
        final qty = _bottleQty[key] ?? 0;
        if (qty > 0) {
          final unit = repo.customerUnitPrice(
            customer,
            productId: product.id,
            variantId: variant.id,
          );
          lines.add(
            DeliveryPriceLine(
              name: variant.label,
              calc: '$qty x $unit',
              amount: qty * unit,
            ),
          );
        }
      }
    }
    return lines;
  }

  double _total(List<DeliveryPriceLine> lines) =>
      lines.fold<double>(0, (sum, l) => sum + l.amount);

  bool _hasItems({
    required bool showNormalCans,
    required bool showCoolCans,
    required List<Product> catalog,
    required Customer customer,
    required WaterPlantRepository repo,
  }) {
    if (showNormalCans && _normal > 0) return true;
    if (showCoolCans && _cool > 0) return true;
    return _bottleInputs(customer, repo, catalog).isNotEmpty;
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

        final bottleCatalog = repo.bottleCatalogForCustomer(customer);
        final showNormalCans = repo.customerUsesNormalCans(customer);
        final showCoolCans = repo.customerUsesCoolCans(customer);
        final priceLines = _priceLines(repo, customer, bottleCatalog);
        final total = _total(priceLines);
        final colorIndex = repo.customers.indexWhere((c) => c.id == widget.customerId);

        return Scaffold(
          backgroundColor: AppColors.surface,
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
                      if (showNormalCans || showCoolCans) ...[
                        const AddDeliverySectionTitle(
                          title: '20L Water Cans',
                          subtitle: 'Customer rates applied',
                        ),
                        if (showNormalCans)
                          AddDeliveryCanStepper(
                            label: 'Normal Water Cans',
                            value: _normal,
                            onChanged: (v) => setState(() => _normal = v),
                          ),
                        if (showCoolCans)
                          AddDeliveryCanStepper(
                            label: 'Cool Water Cans',
                            value: _cool,
                            onChanged: (v) => setState(() => _cool = v),
                          ),
                      ],
                      if (bottleCatalog.isNotEmpty) ...[
                        const AddDeliverySectionTitle(
                          title: 'Water Bottles',
                          subtitle: 'Products assigned to this customer',
                        ),
                        AddDeliveryBottleCatalog(
                          products: bottleCatalog,
                          quantities: _bottleQty,
                          onChanged: (key, qty) => setState(() => _bottleQty[key] = qty),
                        ),
                      ],
                      AddDeliveryPriceSection(lines: priceLines, total: total),
                    ],
                  ),
                ),
                AddDeliverySaveButton(
                  enabled: _hasItems(
                        showNormalCans: showNormalCans,
                        showCoolCans: showCoolCans,
                        catalog: bottleCatalog,
                        customer: customer,
                        repo: repo,
                      ) &&
                      !_saving,
                  isSaving: _saving,
                  onPressed: () async {
                    setState(() => _saving = true);
                    final auth = context.read<AuthRepository>();
                    final staffId = auth.currentUser?.role == AppRole.driver
                        ? auth.currentUser?.driverId
                        : auth.currentUser?.id;
                    try {
                      final delivery = await repo.addDeliveryToCurrentShop(
                        customerId: widget.customerId,
                        date: _date,
                        normalQty: _normal,
                        coolQty: _cool,
                        bottles: _bottleInputs(customer, repo, bottleCatalog),
                        driverId: staffId,
                      );
                      if (!context.mounted) return;
                      context.pushReplacement(
                        '/customers/${widget.customerId}/delivery/success',
                        extra: delivery,
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Delivery not saved. Please try again.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
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
