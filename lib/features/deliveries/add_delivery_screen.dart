import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/auth/app_role.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_info_bar.dart';
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
  int _emptyNormalReturned = 0;
  int _emptyCoolReturned = 0;
  final Map<String, int> _bottleQty = {};
  final Map<String, int> _channelQty = {};
  final Map<String, TextEditingController> _volumeQty = {};
  bool _saving = false;

  TextEditingController _volumeController(String variantId) {
    return _volumeQty.putIfAbsent(variantId, TextEditingController.new);
  }

  int _volumeQuantity(String variantId) {
    final raw = _volumeQty[variantId]?.text.trim() ?? '';
    if (raw.isEmpty) return 0;
    return int.tryParse(raw) ?? 0;
  }

  int _channelQuantity(DeliveryProductType type) {
    if (type.quantityIsVolumeLiters) {
      return _volumeQuantity(type.variantId);
    }
    return _channelQty[type.variantId] ?? 0;
  }

  @override
  void dispose() {
    for (final c in _volumeQty.values) {
      c.dispose();
    }
    super.dispose();
  }

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

  List<BottleDeliveryInput> _bottleInputs(
    Customer customer,
    WaterPlantRepository repo,
    List<Product> catalog,
  ) {
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
              variantId: variant.id,
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
    List<DeliveryProductType> channelTypes,
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
    for (final type in channelTypes) {
      final qty = _channelQuantity(type);
      if (qty <= 0) continue;
      final unit = repo.customerUnitPrice(
        customer,
        productId: type.productId,
        variantId: type.variantId,
      );
      lines.add(
        DeliveryPriceLine(
          name: type.title,
          calc: '$qty x $unit',
          amount: qty * unit,
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
    required List<DeliveryProductType> channelTypes,
    required List<Product> catalog,
    required Customer customer,
    required WaterPlantRepository repo,
  }) {
    if (showNormalCans && _normal > 0) return true;
    if (showCoolCans && _cool > 0) return true;
    for (final type in channelTypes) {
      if (_channelQuantity(type) > 0) return true;
    }
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
        final channelTypes = DeliveryProductType.catalog
            .where(
              (type) => type.productId == CustomerPricingKeys.channelProductId,
            )
            .where(
              (type) => repo.customerVariantEnabled(
                customer,
                productId: type.productId,
                variantId: type.variantId,
              ),
            )
            .toList();
        final hasEnabledProducts =
            showNormalCans ||
            showCoolCans ||
            channelTypes.isNotEmpty ||
            bottleCatalog.isNotEmpty;
        final priceLines = _priceLines(
          repo,
          customer,
          bottleCatalog,
          channelTypes,
        );
        final total = _total(priceLines);

        return Scaffold(
          backgroundColor: AddDeliveryColors.screenBg,
          body: AddDeliveryScaffold(
            child: Column(
              children: [
                AddDeliveryHeader(
                  onBack: () => context.pop(),
                  customerName: customer.name,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      CustomerAddressStrip(customer: customer),
                      AddDeliverySurfaceCard(
                        child: AddDeliveryDateRow(
                          date: _date,
                          onTap: _pickDate,
                        ),
                      ),
                      if (!hasEnabledProducts)
                        const AddDeliveryNoProductsHint()
                      else ...[
                        AddDeliverySurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const AddDeliveryInCardTitle(
                                title: 'Products',
                                subtitle:
                                    'Only products enabled for this customer',
                              ),
                              if (showNormalCans)
                                AddDeliveryCanStepper(
                                  label: 'Normal Can',
                                  value: _normal,
                                  onChanged: (v) => setState(() => _normal = v),
                                ),
                              if (showCoolCans)
                                AddDeliveryCanStepper(
                                  label: 'Cool Can',
                                  value: _cool,
                                  onChanged: (v) => setState(() => _cool = v),
                                ),
                              ...channelTypes.map((type) {
                                if (type.quantityIsVolumeLiters) {
                                  return AddDeliveryVolumeQuantityField(
                                    type: type,
                                    controller: _volumeController(
                                      type.variantId,
                                    ),
                                    onChanged: () => setState(() {}),
                                  );
                                }
                                return AddDeliveryCanStepper(
                                  label: type.title,
                                  value: _channelQty[type.variantId] ?? 0,
                                  onChanged: (v) => setState(
                                    () => _channelQty[type.variantId] = v,
                                  ),
                                );
                              }),
                              AddDeliveryBottleCatalog(
                                products: bottleCatalog,
                                quantities: _bottleQty,
                                onChanged: (key, qty) =>
                                    setState(() => _bottleQty[key] = qty),
                                unitPriceFor: (productId, variantId) =>
                                    repo.customerUnitPrice(
                                      customer,
                                      productId: productId,
                                      variantId: variantId,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (showNormalCans || showCoolCans)
                          AddDeliverySurfaceCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const AddDeliveryInCardTitle(
                                  title: 'Empty cans returned',
                                  subtitle:
                                      'Track cans collected back from customer',
                                ),
                                if (showNormalCans)
                                  AddDeliveryCanStepper(
                                    label: 'Empty Normal Can',
                                    value: _emptyNormalReturned,
                                    onChanged: (v) => setState(
                                      () => _emptyNormalReturned = v,
                                    ),
                                  ),
                                if (showCoolCans)
                                  AddDeliveryCanStepper(
                                    label: 'Empty Cool Can',
                                    value: _emptyCoolReturned,
                                    onChanged: (v) =>
                                        setState(() => _emptyCoolReturned = v),
                                  ),
                              ],
                            ),
                          ),
                      ],
                      AddDeliverySurfaceCard(
                        child: AddDeliveryPriceSection(
                          lines: priceLines,
                          total: total,
                        ),
                      ),
                    ],
                  ),
                ),
                AddDeliverySaveButton(
                  enabled:
                      hasEnabledProducts &&
                      _hasItems(
                        showNormalCans: showNormalCans,
                        showCoolCans: showCoolCans,
                        channelTypes: channelTypes,
                        catalog: bottleCatalog,
                        customer: customer,
                        repo: repo,
                      ),
                  onPressed: () async {
                    final auth = context.read<AuthRepository>();
                    final staffId = auth.currentUser?.role == AppRole.driver
                        ? auth.currentUser?.driverId
                        : auth.currentUser?.id;
                    final channelInputs = channelTypes
                        .where((type) => _channelQuantity(type) > 0)
                        .map(
                          (type) => BottleDeliveryInput(
                            label: type.title,
                            quantity: _channelQuantity(type),
                            unitPrice: repo.customerUnitPrice(
                              customer,
                              productId: type.productId,
                              variantId: type.variantId,
                            ),
                            productId: type.productId,
                            variantId: type.variantId,
                          ),
                        )
                        .toList();
                    setState(() => _saving = true);
                    try {
                      final delivery = await repo.addDeliveryToCurrentShop(
                        customerId: widget.customerId,
                        date: _date,
                        normalQty: _normal,
                        coolQty: _cool,
                        emptyNormalReturned: _emptyNormalReturned,
                        emptyCoolReturned: _emptyCoolReturned,
                        bottles: [
                          ..._bottleInputs(customer, repo, bottleCatalog),
                          ...channelInputs,
                        ],
                        driverId: staffId,
                        driverName: auth.currentUser?.ownerName,
                        customer: customer,
                      );
                      if (!context.mounted) return;
                      context.pushReplacement(
                        '/customers/${widget.customerId}/delivery/success',
                        extra: delivery,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('StateError: ', ''),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
                  loading: _saving,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
