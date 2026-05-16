import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class AddDeliveryColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color stepperBg = Color(0xFFE8F0FE);
  static const Color stepperIcon = Color(0xFF64748B);
  static const Color totalGreen = Color(0xFF16A34A);
  static const Color noteBg = Color(0xFFF3F4F6);
  static const Color primaryBtn = Color(0xFF1A73E8);
  static const Color whatsapp = Color(0xFF25D366);
}

class AddDeliveryHeader extends StatelessWidget {
  const AddDeliveryHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 4, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Add Delivery',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class AddDeliveryCustomerBar extends StatelessWidget {
  const AddDeliveryCustomerBar({
    super.key,
    required this.customer,
    required this.colorIndex,
  });

  final Customer customer;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final bg = CustomersColors.avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: bg,
                child: Text(
                  customer.initials,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AddDeliveryColors.titleNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phone,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AddDeliveryColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chat, color: AddDeliveryColors.whatsapp, size: 26),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AddDeliveryColors.divider),
      ],
    );
  }
}

class AddDeliveryDateRow extends StatelessWidget {
  const AddDeliveryDateRow({
    super.key,
    required this.date,
    required this.onTap,
  });

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                'Date',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AddDeliveryColors.titleNavy,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AddDeliveryColors.fieldBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date.fullDate,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AddDeliveryColors.titleNavy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AddDeliveryColors.labelGrey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AddDeliveryColors.divider),
      ],
    );
  }
}

class AddDeliveryCanStepper extends StatelessWidget {
  const AddDeliveryCanStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AddDeliveryColors.titleNavy,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.remove,
                onTap: value > 0 ? () => onChanged(value - 1) : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AddDeliveryColors.titleNavy,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChanged(value + 1);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AddDeliveryColors.divider),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AddDeliveryColors.stepperBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: AddDeliveryColors.stepperIcon),
        ),
      ),
    );
  }
}

class AddDeliveryPriceSection extends StatelessWidget {
  const AddDeliveryPriceSection({
    super.key,
    required this.normalQty,
    required this.coolQty,
    required this.normalPrice,
    required this.coolPrice,
    required this.total,
  });

  final int normalQty;
  final int coolQty;
  final double normalPrice;
  final double coolPrice;
  final double total;

  @override
  Widget build(BuildContext context) {
    final nSub = normalQty * normalPrice;
    final cSub = coolQty * coolPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'Price Details',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AddDeliveryColors.titleNavy,
            ),
          ),
        ),
        if (normalQty > 0)
          _PriceLine(
            name: 'Normal Cans',
            calc: '$normalQty x ${CurrencyUtils.format(normalPrice)}',
            amount: CurrencyUtils.format(nSub),
          ),
        if (coolQty > 0)
          _PriceLine(
            name: 'Cool Cans',
            calc: '$coolQty x ${CurrencyUtils.format(coolPrice)}',
            amount: CurrencyUtils.format(cSub),
          ),
        if (normalQty == 0 && coolQty == 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Add cans to see price breakdown',
              style: GoogleFonts.poppins(fontSize: 13, color: AddDeliveryColors.labelGrey),
            ),
          ),
        const Divider(height: 1, thickness: 1, color: AddDeliveryColors.divider),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AddDeliveryColors.titleNavy,
                ),
              ),
              Text(
                CurrencyUtils.format(total),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AddDeliveryColors.totalGreen,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AddDeliveryColors.noteBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AddDeliveryColors.labelGrey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Note: Payment will be collected at the end of the month.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      height: 1.4,
                      color: AddDeliveryColors.labelGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.name,
    required this.calc,
    required this.amount,
  });

  final String name;
  final String calc;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: GoogleFonts.poppins(fontSize: 14, color: AddDeliveryColors.titleNavy),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              calc,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AddDeliveryColors.labelGrey),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AddDeliveryColors.titleNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddDeliverySaveButton extends StatelessWidget {
  const AddDeliverySaveButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: AddDeliveryColors.primaryBtn,
              disabledBackgroundColor: AddDeliveryColors.primaryBtn.withValues(alpha: 0.45),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: const Text('Save Delivery'),
          ),
        ),
      ),
    );
  }
}

class AddDeliveryScaffold extends StatelessWidget {
  const AddDeliveryScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: child,
    );
  }
}
