import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/utils/date_utils_ext.dart';
import 'package:sri_sai_ro_water/core/widgets/customer_info_bar.dart';
import 'package:sri_sai_ro_water/data/models/customer.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customer_detail_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/models/product_icon_choice.dart';

/// Matches [CustomerDetailColors] so Add Delivery feels like Customer Details.
abstract final class AddDeliveryColors {
  static const Color titleNavy = CustomerDetailColors.titleNavy;
  static const Color labelGrey = CustomerDetailColors.labelGrey;
  static const Color divider = CustomerDetailColors.cardBorder;
  static const Color fieldBorder = CustomerDetailColors.cardBorder;
  static const Color stepperBg = Color(0xFFEFF6FF);
  static const Color stepperIcon = CustomerDetailColors.statBlue;
  static const Color totalGreen = CustomerDetailColors.statGreen;
  static const Color noteBg = Color(0xFFF8FAFC);
  static const Color primaryBtn = Color(0xFF2563EB);
  static const Color screenBg = CustomerDetailColors.screenBg;

  static BoxDecoration get surfaceCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerDetailColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

/// White card on grey background — same rhythm as customer detail sections.
class AddDeliverySurfaceCard extends StatelessWidget {
  const AddDeliverySurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.fromLTRB(16, 10, 16, 0),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: AddDeliveryColors.surfaceCard,
      child: child,
    );
  }
}

class AddDeliveryInCardTitle extends StatelessWidget {
  const AddDeliveryInCardTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 18,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: CustomerDetailColors.statBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AddDeliveryColors.titleNavy,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AddDeliveryColors.labelGrey,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Delivery',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Record today\'s delivery',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    return CustomerInfoBar(
      customer: customer,
      colorIndex: colorIndex,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
    return Row(
      children: [
        Text(
          'Delivery date',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AddDeliveryColors.titleNavy,
          ),
        ),
        const Spacer(),
        Material(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    date.fullDate,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
    );
  }
}

/// Legacy section title — prefer [AddDeliveryInCardTitle] inside a card.
class AddDeliverySectionTitle extends StatelessWidget {
  const AddDeliverySectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AddDeliveryInCardTitle(title: title, subtitle: subtitle);
  }
}

class AddDeliveryNoProductsHint extends StatelessWidget {
  const AddDeliveryNoProductsHint({super.key});

  @override
  Widget build(BuildContext context) {
    return AddDeliverySurfaceCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: CustomerDetailColors.statOrange,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No products are enabled for this customer. Open the customer profile, tap the products you want to deliver, then return here.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.45,
                  color: AddDeliveryColors.labelGrey,
                ),
              ),
            ),
          ],
        ),
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
    required this.unitPriceFor,
  });

  final List<Product> products;
  final Map<String, int> quantities;
  final void Function(String variantKey, int qty) onChanged;
  final double Function(String productId, String variantId) unitPriceFor;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final product in products) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  productIconByKey(product.iconKey).icon,
                  size: 16,
                  color: AddDeliveryColors.labelGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AddDeliveryColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          for (final variant in product.variants)
            AddDeliveryBottleRow(
              label: variant.label,
              price: unitPriceFor(product.id, variant.id),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    );
  }
}

/// Litres entry for lorry / auto (e.g. 5000 L) — not practical with (+/−).
class AddDeliveryVolumeQuantityField extends StatelessWidget {
  const AddDeliveryVolumeQuantityField({
    super.key,
    required this.type,
    required this.controller,
    required this.onChanged,
    this.compact = false,
  });

  final DeliveryProductType type;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vertical = compact ? 8.0 : 10.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AddDeliveryColors.titleNavy,
                  ),
                ),
                Text(
                  type.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AddDeliveryColors.labelGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: compact ? 112 : 128,
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AddDeliveryColors.titleNavy,
              ),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'L',
                suffixStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AddDeliveryColors.labelGrey,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFBFDBFE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AddDeliveryColors.stepperIcon,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddDeliveryCanStepper extends StatelessWidget {
  const AddDeliveryCanStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxValue,
    this.compact = false,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  /// When set, the + button stops at this value (e.g. customer can balance).
  final int? maxValue;
  final bool compact;

  bool get _atMax => maxValue != null && value >= maxValue!;

  @override
  Widget build(BuildContext context) {
    final vertical = compact ? 8.0 : 10.0;
    final fontSize = compact ? 14.0 : 14.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vertical),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AddDeliveryColors.titleNavy,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.remove,
            compact: compact,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: compact ? 16 : 17,
                fontWeight: FontWeight.w700,
                color: AddDeliveryColors.titleNavy,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            compact: compact,
            onTap: _atMax
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    final next = value + 1;
                    onChanged(
                      maxValue != null ? next.clamp(0, maxValue!) : next,
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 36.0;
    return Material(
      color: AddDeliveryColors.stepperBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFBFDBFE),
            ),
          ),
          child: Icon(
            icon,
            size: compact ? 18 : 20,
            color: onTap == null
                ? AddDeliveryColors.stepperIcon.withValues(alpha: 0.35)
                : AddDeliveryColors.stepperIcon,
          ),
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
        const AddDeliveryInCardTitle(
          title: 'Price details',
          subtitle: 'Billed at month end unless paid early',
        ),
        if (lines.isEmpty)
          Text(
            'Add cans or bottles to see price breakdown',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AddDeliveryColors.labelGrey,
            ),
          )
        else
          for (final line in lines)
            _PriceLine(
              name: line.name,
              calc: line.calc,
              amount: CurrencyUtils.format(line.amount),
            ),
        const Divider(height: 20, thickness: 1, color: AddDeliveryColors.divider),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total amount',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AddDeliveryColors.titleNavy,
                ),
              ),
              Text(
                CurrencyUtils.format(total),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AddDeliveryColors.totalGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AddDeliveryColors.noteBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AddDeliveryColors.divider),
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
                  'Payment is collected at the end of the month.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.4,
                    color: AddDeliveryColors.labelGrey,
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.only(bottom: 8),
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
    return Container(
      color: AddDeliveryColors.screenBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: enabled ? onPressed : null,
              icon: const Icon(Icons.check_rounded, size: 20),
              label: Text(
                'Save delivery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AddDeliveryColors.primaryBtn,
                disabledBackgroundColor:
                    AddDeliveryColors.primaryBtn.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
  Widget build(BuildContext context) => CustomerDetailScaffold(child: child);
}