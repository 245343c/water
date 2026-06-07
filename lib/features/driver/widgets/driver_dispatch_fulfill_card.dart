import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/delivery_localization.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/core/services/delivery_recording_service.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/delivery_line_item.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/models/dispatch_payment_mode.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_can_stepper.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_result_feedback.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

enum _DriverPaymentChoice { pending, waived, cash, upi }

/// Fulfill an admin dispatch: deliver products + optional payment.
class DriverDispatchFulfillCard extends StatefulWidget {
  const DriverDispatchFulfillCard({
    super.key,
    required this.customer,
    required this.dispatch,
    required this.onSaved,
  });

  final Customer customer;
  final CustomerOrder dispatch;
  final void Function(Delivery delivery) onSaved;

  @override
  State<DriverDispatchFulfillCard> createState() =>
      _DriverDispatchFulfillCardState();
}

class _DriverDispatchFulfillCardState extends State<DriverDispatchFulfillCard> {
  late int _normal;
  late int _cool;
  final Map<String, int> _channelQty = {};
  int _emptyNormal = 0;
  int _emptyCool = 0;
  _DriverPaymentChoice _payment = _DriverPaymentChoice.waived;
  bool _saving = false;

  bool get _showPaymentSection =>
      widget.customer.isInstantDispatch || !widget.customer.isMonthlyContract;

  bool get _mustCollect =>
      widget.customer.isInstantDispatch ||
      widget.dispatch.paymentMode == DispatchPaymentMode.collectAtDoor;

  @override
  void initState() {
    super.initState();
    _initQty();
    _payment = _mustCollect
        ? _DriverPaymentChoice.cash
        : _DriverPaymentChoice.waived;
  }

  void _initQty() {
    _normal = widget.dispatch.normalQty;
    _cool = widget.dispatch.coolQty;
    for (final item in widget.dispatch.lineItems) {
      if (item.isNormalCan || item.isCoolCan) continue;
      _channelQty[item.variantId] = item.quantity;
    }
  }

  int get _deliverTotal =>
      _normal + _cool + _channelQty.values.fold(0, (a, b) => a + b);

  double _estimateTotal(WaterPlantRepository repo) {
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
    for (final entry in _channelQty.entries) {
      if (entry.value <= 0) continue;
      total +=
          entry.value *
          repo.customerUnitPrice(
            widget.customer,
            productId: CustomerPricingKeys.channelProductId,
            variantId: entry.key,
          );
    }
    return total;
  }

  List<BottleDeliveryInput> _channelInputs(WaterPlantRepository repo) {
    return repo
        .enabledChannelTypesForCustomer(widget.customer)
        .where((t) => (_channelQty[t.variantId] ?? 0) > 0)
        .map(
          (type) => BottleDeliveryInput(
            label: type.title,
            quantity: _channelQty[type.variantId] ?? 0,
            unitPrice: repo.customerUnitPrice(
              widget.customer,
              productId: type.productId,
              variantId: type.variantId,
            ),
            productId: type.productId,
            variantId: type.variantId,
          ),
        )
        .toList();
  }

  Future<void> _save() async {
    if (_deliverTotal <= 0) {
      _error(context.l10n.enterDelivered);
      return;
    }
    final amount = _estimateTotal(context.read<WaterPlantRepository>());
    if (_payment == _DriverPaymentChoice.cash && amount <= 0) {
      _error(context.l10n.amountMustBeGreaterThanZero);
      return;
    }
    if (_payment == _DriverPaymentChoice.upi && amount <= 0) {
      _error(context.l10n.amountMustBeGreaterThanZero);
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = context.read<WaterPlantRepository>();
      final auth = context.read<AuthRepository>();
      final notifications = context.read<NotificationRepository>();
      final driverId = auth.currentUser?.driverId;
      final driverName = auth.currentUser?.isDriver == true
          ? (repo.driverById(driverId)?.name ?? auth.currentUser?.ownerName)
          : auth.currentUser?.ownerName;

      final bottles = _channelInputs(repo);
      final now = DateTime.now();
      final lines = repo.buildDeliveryLineMaps(
        customerId: widget.customer.id,
        date: now,
        normalQty: _normal,
        coolQty: _cool,
        bottles: bottles,
        customer: widget.customer,
      );

      final collectionStatus = switch (_payment) {
        _DriverPaymentChoice.cash => 'collected',
        _DriverPaymentChoice.upi => 'collected',
        _DriverPaymentChoice.pending => 'pending',
        _DriverPaymentChoice.waived => 'waived',
      };
      final collectionMethod = switch (_payment) {
        _DriverPaymentChoice.upi => 'upi',
        _ => 'cash',
      };
      final collectedAmount =
          _payment == _DriverPaymentChoice.cash ||
              _payment == _DriverPaymentChoice.upi
          ? amount
          : 0.0;

      final delivery = await repo.fulfillInstantDispatchInFirestore(
        orderId: widget.dispatch.id,
        date: now,
        lines: lines,
        emptyNormalReturned: _emptyNormal,
        emptyCoolReturned: _emptyCool,
        collectionStatus: collectionStatus,
        collectedAmount: collectedAmount,
        collectionMethod: collectionMethod,
        driverId: driverId,
        driverName: driverName,
      );

      final order = repo.orderById(widget.dispatch.id);
      if (order != null) {
        notifications.notifyAdminInstantFulfilled(
          order: order,
          customerName: widget.customer.name,
          summary: order.itemsSummary,
        );
      }

      widget.onSaved(delivery);
    } on DeliveryValidationException catch (e) {
      _error(e.message);
    } catch (e) {
      _error(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _error(String msg) {
    showDriverResultFeedback(
      context,
      success: false,
      title: context.l10n.couldNotSave,
      message: msg,
    );
  }

  void _copyUpiHint(WaterPlantRepository repo) {
    final shop = repo.shopById(
      widget.dispatch.shopId ?? WaterPlantRepository.defaultShopId,
    );
    final phone = shop?.phone ?? widget.customer.phone;
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.shopNumberCopiedUpi,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WaterPlantRepository>();
    final strings = context.l10n;
    final showNormal = repo.customerUsesNormalCans(widget.customer);
    final showCool = repo.customerUsesCoolCans(widget.customer);
    final channelTypes = repo.enabledChannelTypesForCustomer(widget.customer);
    final estimate = _estimateTotal(repo);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: DriverColors.whiteCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.customer.isInstantDispatch
                      ? '${strings.instantDelivery} · ${strings.collectCash}'
                      : strings.deliveries,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.dispatch.paymentMode.label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: DriverColors.labelGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.orderItemsSummary(widget.dispatch),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: DriverColors.titleNavy,
            ),
          ),
          if (widget.dispatch.customerNote != null &&
              widget.dispatch.customerNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.dispatch.customerNote!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: DriverColors.labelGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            strings.actualDelivered,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DriverColors.labelGrey,
            ),
          ),
          const SizedBox(height: 8),
          if (showNormal)
            DriverCanStepperRow(
              label: strings.normal,
              value: _normal,
              color: const Color(0xFF2563EB),
              onChanged: (v) => setState(() => _normal = v),
            ),
          if (showCool)
            DriverCanStepperRow(
              label: strings.cool,
              value: _cool,
              color: DriverColors.accent,
              onChanged: (v) => setState(() => _cool = v),
            ),
          for (final type in channelTypes)
            DriverCanStepperRow(
              label: strings.deliveryProductTitle(type),
              value: _channelQty[type.variantId] ?? 0,
              color: DriverColors.accent,
              onChanged: (v) => setState(() => _channelQty[type.variantId] = v),
            ),
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
            if (showCool)
              DriverCanStepperRow(
                label: strings.emptyCool,
                value: _emptyCool,
                color: DriverColors.accent,
                onChanged: (v) => setState(() => _emptyCool = v),
              ),
          ],
          if (_showPaymentSection) ...[
            const SizedBox(height: 14),
            Text(
              strings.payment,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DriverColors.labelGrey,
              ),
            ),
            const SizedBox(height: 8),
            _PaymentChip(
              label: strings.cashCollected,
              selected: _payment == _DriverPaymentChoice.cash,
              onTap: () => setState(() => _payment = _DriverPaymentChoice.cash),
            ),
            const SizedBox(height: 6),
            _PaymentChip(
              label: strings.upiReceived,
              selected: _payment == _DriverPaymentChoice.upi,
              onTap: () => setState(() => _payment = _DriverPaymentChoice.upi),
            ),
            const SizedBox(height: 6),
            _PaymentChip(
              label: strings.notPaidAdmin,
              selected: _payment == _DriverPaymentChoice.pending,
              onTap: () =>
                  setState(() => _payment = _DriverPaymentChoice.pending),
            ),
            if (!_mustCollect) ...[
              const SizedBox(height: 6),
              _PaymentChip(
                label: strings.payLater,
                selected: _payment == _DriverPaymentChoice.waived,
                onTap: () =>
                    setState(() => _payment = _DriverPaymentChoice.waived),
              ),
            ],
            if (_payment == _DriverPaymentChoice.upi) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _copyUpiHint(repo),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: Text(
                  strings.copyShopNumberForUpi,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DriverColors.accent,
                  side: const BorderSide(color: DriverColors.accent),
                ),
              ),
            ],
            if (estimate > 0 &&
                (_payment == _DriverPaymentChoice.cash ||
                    _payment == _DriverPaymentChoice.upi)) ...[
              const SizedBox(height: 10),
              Text(
                '${strings.amount}: ${CurrencyUtils.format(estimate)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DriverColors.titleNavy,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: DriverColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    strings.saveDelivery,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? DriverColors.accent.withValues(alpha: 0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? DriverColors.accent : DriverColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: selected ? DriverColors.accent : DriverColors.labelGrey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DriverColors.titleNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
