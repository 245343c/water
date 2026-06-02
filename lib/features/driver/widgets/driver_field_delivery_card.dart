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
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

/// On-site flow: ask customer → enter cans delivered → save → notify admin & customer.
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
              'Normal: $_normal · Cool: $_cool',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
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
        driverMode: true,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      widget.onSaved(delivery);
      setState(() {
        _normal = 0;
        _cool = 0;
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            DriverColors.accentBright.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DriverColors.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: DriverColors.accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DriverColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: DriverColors.accent, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record at doorstep',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: DriverColors.titleNavy,
                        ),
                      ),
                      Text(
                        'Ask customer → enter cans → save',
                        style: GoogleFonts.poppins(fontSize: 12, color: DriverColors.labelGrey),
                      ),
                    ],
                  ),
                ),
              ],
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
                        'Admin confirmed ${widget.suggestedOrder!.cansSummary}. '
                        'Ask customer — adjust below if different.',
                        style: GoogleFonts.poppins(fontSize: 12, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (showNormal) _CanStepperRow(
              label: 'Normal cans',
              subtitle: '20L room temperature',
              value: _normal,
              color: const Color(0xFF2563EB),
              onChanged: (v) => setState(() => _normal = v),
            ),
            if (showCool) ...[
              if (showNormal) const SizedBox(height: 12),
              _CanStepperRow(
                label: 'Cool cans',
                subtitle: '20L chilled',
                value: _cool,
                color: const Color(0xFF0D9488),
                onChanged: (v) => setState(() => _cool = v),
              ),
            ],
            if (_total > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: DriverColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total $_total cans',
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
      ),
    );
  }
}

class _CanStepperRow extends StatelessWidget {
  const _CanStepperRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

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
                  label,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: DriverColors.labelGrey)),
              ],
            ),
          ),
          _RoundBtn(
            icon: Icons.remove,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          _RoundBtn(
            icon: Icons.add,
            filled: true,
            color: color,
            onTap: value < DeliveryRecordingService.maxCansPerDelivery
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    this.onTap,
    this.filled = false,
    this.color = DriverColors.accent,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : color.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: filled ? Colors.white : color, size: 22),
        ),
      ),
    );
  }
}
