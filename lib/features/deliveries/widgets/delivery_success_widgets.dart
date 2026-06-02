import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/delivery.dart';

abstract final class DeliverySuccessColors {
  static const Color bgMint = Color(0xFFE8F5E9);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color successGreenLight = Color(0xFF4CAF50);
  static const Color ringGreen = Color(0xFFA5D6A7);
  static const Color titleNavy = AppColors.textPrimary;
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color valueNavy = Color(0xFF1E40AF);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color notifyBg = Color(0xFFE8F5E9);
  static const Color notifyBorder = Color(0xFFC8E6C9);
}

class DeliverySuccessView extends StatelessWidget {
  const DeliverySuccessView({
    super.key,
    required this.customerName,
    required this.delivery,
    required this.onContinue,
  });

  final String customerName;
  final Delivery delivery;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DeliverySuccessColors.bgMint,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: 20),
                    const _SuccessHero(),
                    const SizedBox(height: 20),
                    Text(
                      delivery.isEmptyReturnOnly
                          ? 'Empty Return Saved!'
                          : 'Delivery Saved!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: DeliverySuccessColors.titleNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      delivery.isEmptyReturnOnly
                          ? 'Customer can balance is updated.'
                          : 'Payment will be collected at month end.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: DeliverySuccessColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SummaryCard(customerName: customerName, delivery: delivery),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: DeliverySuccessColors.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHero extends StatefulWidget {
  const _SuccessHero();

  @override
  State<_SuccessHero> createState() => _SuccessHeroState();
}

class _SuccessHeroState extends State<_SuccessHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _pulse = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 36,
            top: 18,
            child: _ConfettiDiamond(color: Color(0xFFFFEB3B)),
          ),
          const Positioned(
            right: 48,
            top: 28,
            child: _ConfettiDiamond(color: Color(0xFF81D4FA)),
          ),
          const Positioned(
            left: 72,
            bottom: 12,
            child: _ConfettiDiamond(color: Color(0xFFA5D6A7), size: 8),
          ),
          const Positioned(
            right: 80,
            bottom: 20,
            child: _ConfettiDiamond(color: Color(0xFFFFCC80), size: 9),
          ),
          const Positioned(
            right: 28,
            top: 8,
            child: _ConfettiDiamond(color: Color(0xFFCE93D8), size: 7),
          ),
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DeliverySuccessColors.ringGreen.withValues(alpha: 0.45),
            ),
          ),
          FadeTransition(
            opacity: Tween<double>(begin: 0.55, end: 0).animate(_pulse),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.45, end: 1.35).animate(_pulse),
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DeliverySuccessColors.successGreen.withValues(alpha: 0.35),
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: DeliverySuccessColors.successGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x402E7D32),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiDiamond extends StatelessWidget {
  const _ConfettiDiamond({required this.color, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.customerName, required this.delivery});

  final String customerName;
  final Delivery delivery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            delivery.isEmptyReturnOnly ? 'Return Summary' : 'Delivery Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DeliverySuccessColors.titleNavy,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Customer', value: customerName),
          if (delivery.isEmptyReturnOnly) ...[
            if (delivery.emptyNormalReturned > 0)
              _SummaryRow(
                label: 'Empty Normal Can',
                value: '${delivery.emptyNormalReturned}',
              ),
            if (delivery.emptyCoolReturned > 0)
              _SummaryRow(
                label: 'Empty Cool Can',
                value: '${delivery.emptyCoolReturned}',
              ),
          ],
          for (final line in delivery.lines) ...[
            const SizedBox(height: 12),
            const SizedBox(height: 10),
            _SummaryRow(
              label: line.label,
              value:
                  '${line.quantity} × ${CurrencyUtils.format(line.unitPrice)}',
            ),
          ],
          if (!delivery.isEmptyReturnOnly) ...[
            if (delivery.emptyNormalReturned > 0) ...[
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Empty Normal Can',
                value: '${delivery.emptyNormalReturned}',
              ),
            ],
            if (delivery.emptyCoolReturned > 0) ...[
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Empty Cool Can',
                value: '${delivery.emptyCoolReturned}',
              ),
            ],
          ],
          if (!delivery.isEmptyReturnOnly) ...[
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Total Amount',
              value: CurrencyUtils.format(delivery.totalAmount),
              valueColor: DeliverySuccessColors.successGreenLight,
            ),
          ],
          const SizedBox(height: 12),
          _SummaryRow(label: 'Date', value: delivery.date.fullDate),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: DeliverySuccessColors.labelGrey,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? DeliverySuccessColors.valueNavy,
          ),
        ),
      ],
    );
  }
}

class DeliverySuccessScaffold extends StatelessWidget {
  const DeliverySuccessScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PremiumResponsiveBody(maxWidth: 1180, child: child),
    );
  }
}
