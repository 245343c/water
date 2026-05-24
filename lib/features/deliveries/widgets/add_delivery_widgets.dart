import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
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
    return AdminPageHeader(
      title: 'Add Delivery',
      subtitle: 'Record cans and notify customer',
      onBack: onBack,
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
    final bg = CustomersColors
        .avatarBgs[colorIndex % CustomersColors.avatarBgs.length];

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
              const Icon(
                Icons.chat,
                color: AddDeliveryColors.whatsapp,
                size: 26,
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AddDeliveryColors.divider,
        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AddDeliveryColors.labelGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AddDeliveryColors.divider,
        ),
      ],
    );
  }
}

class AddDeliverySectionTitle extends StatelessWidget {
  const AddDeliverySectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AddDeliveryColors.titleNavy,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AddDeliveryColors.labelGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AddDeliveryBottleCatalog extends StatelessWidget {
  const AddDeliveryBottleCatalog({
    super.key,
    required this.products,
    required this.quantities,
    required this.onChanged,
  });

  final List<Product> products;
  final Map<String, int> quantities;
  final void Function(String variantKey, int qty) onChanged;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(
          'Add bottle products from the Products tab first.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AddDeliveryColors.labelGrey,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final product in products) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              product.name,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AddDeliveryColors.labelGrey,
              ),
            ),
          ),
          for (final variant in product.variants)
            AddDeliveryBottleRow(
              label: variant.label,
              price: variant.price,
              quantity: quantities['${product.id}|${variant.id}'] ?? 0,
              onChanged: (q) => onChanged('${product.id}|${variant.id}', q),
            ),
        ],
      ],
    );
  }
}

class AddDeliveryBottleRow extends StatelessWidget {
  const AddDeliveryBottleRow({
    super.key,
    required this.label,
    required this.price,
    required this.quantity,
    required this.onChanged,
  });

  final String label;
  final double price;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AddDeliveryColors.titleNavy,
                      ),
                    ),
                    Text(
                      CurrencyUtils.format(price),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AddDeliveryColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              _StepBtn(
                icon: Icons.remove,
                onTap: quantity > 0 ? () => onChanged(quantity - 1) : null,
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AddDeliveryColors.titleNavy,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChanged(quantity + 1);
                },
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AddDeliveryColors.divider,
        ),
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
        const Divider(
          height: 1,
          thickness: 1,
          color: AddDeliveryColors.divider,
        ),
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

class DeliveryPriceLine {
  const DeliveryPriceLine({
    required this.name,
    required this.calc,
    required this.amount,
  });

  final String name;
  final String calc;
  final double amount;
}

class AddDeliveryPriceSection extends StatelessWidget {
  const AddDeliveryPriceSection({
    super.key,
    required this.lines,
    required this.total,
  });

  final List<DeliveryPriceLine> lines;
  final double total;

  @override
  Widget build(BuildContext context) {
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
        if (lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Add cans or bottles to see price breakdown',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AddDeliveryColors.labelGrey,
              ),
            ),
          )
        else
          for (final line in lines)
            _PriceLine(
              name: line.name,
              calc: line.calc,
              amount: CurrencyUtils.format(line.amount),
            ),
        const Divider(
          height: 1,
          thickness: 1,
          color: AddDeliveryColors.divider,
        ),
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
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AddDeliveryColors.labelGrey,
                ),
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
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AddDeliveryColors.titleNavy,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              calc,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AddDeliveryColors.labelGrey,
              ),
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
              disabledBackgroundColor: AddDeliveryColors.primaryBtn.withValues(
                alpha: 0.45,
              ),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
      child: PremiumResponsiveBody(maxWidth: 1180, child: child),
    );
  }
}
