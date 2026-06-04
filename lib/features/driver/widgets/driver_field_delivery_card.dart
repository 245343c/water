import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/core/services/delivery_recording_service.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_can_stepper.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// On-site flow: deliver cans + collect empties → save → notify admin & customer.
class DriverFieldDeliveryCard extends StatefulWidget {
  const DriverFieldDeliveryCard({
    super.key,
    required this.customer,
    required this.onSaved,
    this.suggestedOrder,
  });

  final Customer customer;
  final void Function(Delivery delivery) onSaved;

  /// Admin-accepted order — pre-fills hint; driver confirms actual qty at door.
  final CustomerOrder? suggestedOrder;

  @override
  State<DriverFieldDeliveryCard> createState() => _DriverFieldDeliveryCardState();
}

class _DriverFieldDeliveryCardState extends State<DriverFieldDeliveryCard> {
  late int _normal;
  late int _cool;
  int _emptyNormal = 0;
  int _emptyCool = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final order = widget.suggestedOrder;
    _normal = order?.normalQty ?? 0;
    _cool = order?.coolQty ?? 0;
  }

  @override
  void didUpdateWidget(DriverFieldDeliveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestedOrder?.id != widget.suggestedOrder?.id) {
      final order = widget.suggestedOrder;
      _normal = order?.normalQty ?? 0;
      _cool = order?.coolQty ?? 0;
    }
  }

  int get _total => _normal + _cool;
  int get _emptyTotal => _emptyNormal + _emptyCool;

  double _estimateTotal(WaterPlantRepository repo) {
    var total = 0.0;
    if (_normal > 0) {
      total += _normal *
          repo.customerUnitPrice(
            widget.customer,
            productId: CustomerPricingKeys.canProductId,
            variantId: CustomerPricingKeys.normalVariantId,
          );
    }
    if (_cool > 0) {
      total += _cool *
          repo.customerUnitPrice(
            widget.customer,
            productId: CustomerPricingKeys.canProductId,
            variantId: CustomerPricingKeys.coolVariantId,
          );
    }
    return total;
  }

  Future<void> _confirmAndSave() async {
    if (_total <= 0) {
      _showError('How many cans did you deliver?');
      return;
    }

    final repo = context.read<WaterPlantRepository>();
    final estimate = _estimateTotal(repo);

    final emptyLines = <String>[];
    if (_emptyNormal > 0) emptyLines.add('Empty normal: $_emptyNormal');
    if (_emptyCool > 0) emptyLines.add('Empty cool: $_emptyCool');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm delivery', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customer.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Delivered — Normal: $_normal · Cool: $_cool',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            if (emptyLines.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                emptyLines.join('\n'),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: DriverColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Est. amount ${CurrencyUtils.format(estimate)}',
              style: GoogleFonts.poppins(fontSize: 13, color: DriverColors.labelGrey),
            ),
            const SizedBox(height: 12),
            Text(
              'Admin & customer will be notified instantly.',
              style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.accent),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: DriverColors.accent),
            child: Text('Save & notify', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final recording = context.read<DeliveryRecordingService>();
      final delivery = recording.recordCansDelivery(
        customerId: widget.customer.id,
        normalQty: _normal,
        coolQty: _cool,
        emptyNormalReturned: _emptyNormal,
        emptyCoolReturned: _emptyCool,
        driverMode: true,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      widget.onSaved(delivery);
      setState(() {
        _normal = 0;
        _cool = 0;
        _emptyNormal = 0;
        _emptyCool = 0;
        _saving = false;
      });
    } on DeliveryValidationException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('Could not save. Try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WaterPlantRepository>();
    final showNormal = repo.customerUsesNormalCans(widget.customer);
    final showCool = repo.customerUsesCoolCans(widget.customer);
    final estimate = _total > 0 ? _estimateTotal(repo) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: DriverColors.whiteCard,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Deliver & collect empties',
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
                    const Icon(Icons.verified_rounded, color: Color(0xFFEA580C), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Admin confirmed ${widget.suggestedOrder!.itemsSummary}. '
                        'Ask customer — adjust below if different.',
                        style: GoogleFonts.poppins(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (showNormal)
              DriverCanStepperRow(
                label: 'Normal cans',
                subtitle: '20L room temperature',
                value: _normal,
                color: const Color(0xFF2563EB),
                onChanged: (v) => setState(() => _normal = v),
              ),
            if (showCool) ...[
              if (showNormal) const SizedBox(height: 12),
              DriverCanStepperRow(
                label: 'Cool cans',
                subtitle: '20L chilled',
                value: _cool,
                color: DriverColors.accent,
                onChanged: (v) => setState(() => _cool = v),
              ),
            ],
            if (showNormal || showCool) ...[
              const SizedBox(height: 12),
              Text(
                'Empty returned',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DriverColors.labelGrey,
                ),
              ),
              const SizedBox(height: 8),
              if (showNormal)
                DriverCanStepperRow(
                  label: 'Empty normal',
                  value: _emptyNormal,
                  color: const Color(0xFF2563EB),
                  onChanged: (v) => setState(() => _emptyNormal = v),
                ),
              if (showCool) ...[
                if (showNormal) const SizedBox(height: 12),
                DriverCanStepperRow(
                  label: 'Empty cool',
                  value: _emptyCool,
                  color: DriverColors.accent,
                  onChanged: (v) => setState(() => _emptyCool = v),
                ),
              ],
            ],
            if (_total > 0 || _emptyTotal > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: DriverColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    if (_total > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivered $_total cans',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                      if (_total > 0) const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.recycling_rounded,
                            size: 16,
                            color: DriverColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Returning $_emptyTotal empty can${_emptyTotal == 1 ? '' : 's'}',
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
                onPressed: _saving || _total <= 0 ? null : _confirmAndSave,
                style: FilledButton.styleFrom(
                  backgroundColor: DriverColors.accent,
                  disabledBackgroundColor: DriverColors.cardBorder,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_active_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Save & notify customer',
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
