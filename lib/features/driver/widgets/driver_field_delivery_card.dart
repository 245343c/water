import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/delivery_localization.dart';
import 'package:sri_sai_ro_water/core/services/delivery_recording_service.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_can_stepper.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_result_feedback.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// On-site flow: deliver enabled products + collect empties, then notify admin.
class DriverFieldDeliveryCard extends StatefulWidget {
  const DriverFieldDeliveryCard({
    super.key,
    required this.customer,
    required this.onSaved,
    this.suggestedOrder,
  });

  final Customer customer;
  final void Function(Delivery delivery) onSaved;

  /// Admin-accepted order hint. Driver confirms actual qty at the door.
  final CustomerOrder? suggestedOrder;

  @override
  State<DriverFieldDeliveryCard> createState() =>
      _DriverFieldDeliveryCardState();
}

class _DriverFieldDeliveryCardState extends State<DriverFieldDeliveryCard> {
  late int _normal;
  late int _cool;
  final Map<String, int> _bottleQty = {};
  final Map<String, int> _channelQty = {};
  final Map<String, TextEditingController> _volumeQty = {};
  int _emptyNormal = 0;
  int _emptyCool = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applySuggestedOrder();
  }

  @override
  void didUpdateWidget(DriverFieldDeliveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestedOrder?.id != widget.suggestedOrder?.id) {
      _applySuggestedOrder();
    }
  }

  @override
  void dispose() {
    for (final controller in _volumeQty.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applySuggestedOrder() {
    final order = widget.suggestedOrder;
    _normal = order?.normalQty ?? 0;
    _cool = order?.coolQty ?? 0;
    _channelQty.clear();
    if (order == null) return;
    for (final item in order.lineItems) {
      if (item.isNormalCan || item.isCoolCan) continue;
      _channelQty[item.variantId] = item.quantity;
    }
  }

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

  int _bottleTotal() => _bottleQty.values.fold(0, (sum, qty) => sum + qty);

  int _channelTotal(List<DeliveryProductType> channelTypes) {
    return channelTypes.fold(0, (sum, type) => sum + _channelQuantity(type));
  }

  int _deliveryTotal(List<DeliveryProductType> channelTypes) {
    return _normal + _cool + _channelTotal(channelTypes) + _bottleTotal();
  }

  int get _emptyTotal => _emptyNormal + _emptyCool;

  double _estimateTotal({
    required WaterPlantRepository repo,
    required List<Product> bottleCatalog,
    required List<DeliveryProductType> channelTypes,
  }) {
    var total = 0.0;
    if (_normal > 0) {
      total +=
          _normal *
          repo.customerUnitPrice(
            widget.customer,
            productId: CustomerPricingKeys.canProductId,
            variantId: CustomerPricingKeys.normalVariantId,
          );
    }
    if (_cool > 0) {
      total +=
          _cool *
          repo.customerUnitPrice(
            widget.customer,
            productId: CustomerPricingKeys.canProductId,
            variantId: CustomerPricingKeys.coolVariantId,
          );
    }
    for (final type in channelTypes) {
      final qty = _channelQuantity(type);
      if (qty <= 0) continue;
      total +=
          qty *
          repo.customerUnitPrice(
            widget.customer,
            productId: type.productId,
            variantId: type.variantId,
          );
    }
    for (final product in bottleCatalog) {
      for (final variant in product.variants) {
        final key = '${product.id}|${variant.id}';
        final qty = _bottleQty[key] ?? 0;
        if (qty <= 0) continue;
        total +=
            qty *
            repo.customerUnitPrice(
              widget.customer,
              productId: product.id,
              variantId: variant.id,
            );
      }
    }
    return total;
  }

  List<BottleDeliveryInput> _extraInputs({
    required WaterPlantRepository repo,
    required List<Product> bottleCatalog,
    required List<DeliveryProductType> channelTypes,
  }) {
    final inputs = <BottleDeliveryInput>[];
    for (final type in channelTypes) {
      final qty = _channelQuantity(type);
      if (qty <= 0) continue;
      inputs.add(
        BottleDeliveryInput(
          label: type.title,
          quantity: qty,
          unitPrice: repo.customerUnitPrice(
            widget.customer,
            productId: type.productId,
            variantId: type.variantId,
          ),
          productId: type.productId,
          variantId: type.variantId,
        ),
      );
    }
    for (final product in bottleCatalog) {
      for (final variant in product.variants) {
        final key = '${product.id}|${variant.id}';
        final qty = _bottleQty[key] ?? 0;
        if (qty <= 0) continue;
        inputs.add(
          BottleDeliveryInput(
            label: variant.label,
            quantity: qty,
            unitPrice: repo.customerUnitPrice(
              widget.customer,
              productId: product.id,
              variantId: variant.id,
            ),
            productId: product.id,
            variantId: variant.id,
          ),
        );
      }
    }
    return inputs;
  }

  Future<void> _saveDelivery({
    required List<Product> bottleCatalog,
    required List<DeliveryProductType> channelTypes,
  }) async {
    if (_deliveryTotal(channelTypes) <= 0) {
      _showError(context.l10n.enterDelivered);
      return;
    }

    final repo = context.read<WaterPlantRepository>();
    setState(() => _saving = true);
    try {
      final recording = context.read<DeliveryRecordingService>();
      final delivery = await recording.recordCansDelivery(
        customerId: widget.customer.id,
        normalQty: _normal,
        coolQty: _cool,
        emptyNormalReturned: _emptyNormal,
        emptyCoolReturned: _emptyCool,
        extraBottles: _extraInputs(
          repo: repo,
          bottleCatalog: bottleCatalog,
          channelTypes: channelTypes,
        ),
        driverMode: true,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      widget.onSaved(delivery);
      setState(() {
        _normal = 0;
        _cool = 0;
        _bottleQty.clear();
        _channelQty.clear();
        for (final controller in _volumeQty.values) {
          controller.clear();
        }
        _emptyNormal = 0;
        _emptyCool = 0;
        _saving = false;
      });
    } on DeliveryValidationException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(context.l10n.couldNotSave);
    }
  }

  void _showError(String msg) {
    showDriverResultFeedback(
      context,
      success: false,
      title: context.l10n.couldNotSave,
      message: msg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WaterPlantRepository>();
    final strings = context.l10n;
    final showNormal = repo.customerUsesNormalCans(widget.customer);
    final showCool = repo.customerUsesCoolCans(widget.customer);
    final channelTypes = repo.enabledChannelTypesForCustomer(widget.customer);
    final bottleCatalog = repo.bottleCatalogForCustomer(widget.customer);
    final deliveredTotal = _deliveryTotal(channelTypes);
    final estimate = deliveredTotal > 0
        ? _estimateTotal(
            repo: repo,
            bottleCatalog: bottleCatalog,
            channelTypes: channelTypes,
          )
        : 0.0;
    final hasEnabledProducts =
        showNormal ||
        showCool ||
        channelTypes.isNotEmpty ||
        bottleCatalog.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: DriverColors.whiteCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.deliverProducts,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DriverColors.titleNavy,
            ),
          ),
          if (widget.suggestedOrder != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFFEA580C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      strings.adminConfirmedAdjust(
                        strings.orderItemsSummary(widget.suggestedOrder!),
                      ),
                      style: GoogleFonts.poppins(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (!hasEnabledProducts)
            Text(
              strings.noProductsEnabled,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: DriverColors.labelGrey,
              ),
            )
          else ...[
            if (showNormal)
              DriverCanStepperRow(
                label: strings.normalCans,
                subtitle: strings.twentyLRoomTemperature,
                value: _normal,
                color: const Color(0xFF2563EB),
                onChanged: (v) => setState(() => _normal = v),
              ),
            if (showCool) ...[
              if (showNormal) const SizedBox(height: 12),
              DriverCanStepperRow(
                label: strings.coolCans,
                subtitle: strings.twentyLChilled,
                value: _cool,
                color: DriverColors.accent,
                onChanged: (v) => setState(() => _cool = v),
              ),
            ],
            for (final type in channelTypes) ...[
              if (showNormal || showCool || channelTypes.indexOf(type) > 0)
                const SizedBox(height: 12),
              if (type.quantityIsVolumeLiters)
                _DriverVolumeQuantityRow(
                  type: type,
                  strings: strings,
                  controller: _volumeController(type.variantId),
                  onChanged: () => setState(() {}),
                )
              else
                DriverCanStepperRow(
                  label: strings.deliveryProductTitle(type),
                  subtitle: strings.deliveryProductSubtitle(type),
                  value: _channelQty[type.variantId] ?? 0,
                  color: DriverColors.accent,
                  onChanged: (v) =>
                      setState(() => _channelQty[type.variantId] = v),
                ),
            ],
            for (final product in bottleCatalog)
              for (final variant in product.variants) ...[
                const SizedBox(height: 12),
                DriverCanStepperRow(
                  label: variant.label,
                  subtitle: product.name,
                  value: _bottleQty['${product.id}|${variant.id}'] ?? 0,
                  color: DriverColors.accent,
                  onChanged: (v) => setState(
                    () => _bottleQty['${product.id}|${variant.id}'] = v,
                  ),
                ),
              ],
          ],
          if (showNormal || showCool) ...[
            const SizedBox(height: 12),
            Text(
              strings.emptyReturned,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DriverColors.labelGrey,
              ),
            ),
            const SizedBox(height: 8),
            if (showNormal)
              DriverCanStepperRow(
                label: strings.emptyNormal,
                value: _emptyNormal,
                color: const Color(0xFF2563EB),
                onChanged: (v) => setState(() => _emptyNormal = v),
              ),
            if (showCool) ...[
              if (showNormal) const SizedBox(height: 12),
              DriverCanStepperRow(
                label: strings.emptyCool,
                value: _emptyCool,
                color: DriverColors.accent,
                onChanged: (v) => setState(() => _emptyCool = v),
              ),
            ],
          ],
          if (deliveredTotal > 0 || _emptyTotal > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: DriverColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (deliveredTotal > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.deliveredItems(deliveredTotal),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          CurrencyUtils.format(estimate),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: DriverColors.accent,
                          ),
                        ),
                      ],
                    ),
                  if (_emptyTotal > 0) ...[
                    if (deliveredTotal > 0) const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.recycling_rounded,
                          size: 16,
                          color: DriverColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          strings.returningEmpty(_emptyTotal),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DriverColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _saving || deliveredTotal <= 0
                  ? null
                  : () => _saveDelivery(
                      bottleCatalog: bottleCatalog,
                      channelTypes: channelTypes,
                    ),
              style: FilledButton.styleFrom(
                backgroundColor: DriverColors.accent,
                disabledBackgroundColor: DriverColors.cardBorder,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          strings.saveDelivery,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverVolumeQuantityRow extends StatelessWidget {
  const _DriverVolumeQuantityRow({
    required this.type,
    required this.strings,
    required this.controller,
    required this.onChanged,
  });

  final DeliveryProductType type;
  final AppStrings strings;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DriverColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.deliveryProductTitle(type),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  strings.deliveryProductSubtitle(type),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: DriverColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: DriverColors.accent,
              ),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'L',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DriverColors.cardBorder),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
