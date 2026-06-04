import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/models/product_icon_choice.dart';
import 'package:sri_sai_ro_water/features/products/widgets/products_screen_widgets.dart';

abstract final class AddProductColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color primaryBtn = Color(0xFF1A73E8);
}

class AddProductHeader extends StatelessWidget {
  const AddProductHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Add Product',
      subtitle: 'For your product catalog',
      onBack: onBack,
    );
  }
}

/// White card shell — matches Products page sections.
class AddProductSectionCard extends StatelessWidget {
  const AddProductSectionCard({
    super.key,
    this.title,
    required this.child,
  });

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: ProductsColors.whiteCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AddProductColors.titleNavy,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Optional stock & notes — collapsed by default.
class AddProductAdvancedSection extends StatefulWidget {
  const AddProductAdvancedSection({
    super.key,
    required this.stockController,
    required this.notesController,
  });

  final TextEditingController stockController;
  final TextEditingController notesController;

  @override
  State<AddProductAdvancedSection> createState() =>
      _AddProductAdvancedSectionState();
}

class _AddProductAdvancedSectionState extends State<AddProductAdvancedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ProductsColors.whiteCard,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: AddProductColors.labelGrey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advanced',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AddProductColors.titleNavy,
                            ),
                          ),
                          Text(
                            'Stock & internal notes (optional)',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AddProductColors.labelGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AddProductColors.labelGrey,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AddProductColors.fieldBorder),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  AddEditCustomerField(
                    label: 'Stock quantity',
                    controller: widget.stockController,
                    hint: 'e.g. 50',
                    icon: Icons.numbers_outlined,
                    keyboardType: TextInputType.number,
                    validator: validateStockQty,
                  ),
                  AddEditCustomerField(
                    label: 'Notes',
                    controller: widget.notesController,
                    hint: 'Visible to your team only',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AddProductIconSelector extends StatelessWidget {
  const AddProductIconSelector({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: kProductIconChoices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, i) {
        final choice = kProductIconChoices[i];
        final selected = choice.key == selectedKey;
        return Material(
          color: selected
              ? ProductsColors.statBlue.withValues(alpha: 0.12)
              : const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onSelected(choice.key),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? ProductsColors.statBlue
                      : AddProductColors.fieldBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    choice.icon,
                    size: 24,
                    color: selected
                        ? ProductsColors.statBlue
                        : AddProductColors.labelGrey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    choice.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      color: AddProductColors.titleNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class AddProductCategorySelector extends StatelessWidget {
  const AddProductCategorySelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ProductCategory selected;
  final ValueChanged<ProductCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TYPE',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AddProductColors.labelGrey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TypeChip(
                  icon: Icons.water_drop_outlined,
                  label: 'Bottle',
                  selected: selected == ProductCategory.bottle,
                  accent: ProductsColors.statBlue,
                  onTap: () => onSelected(ProductCategory.bottle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeChip(
                  icon: Icons.local_drink_outlined,
                  label: 'Can',
                  selected: selected == ProductCategory.can,
                  accent: ProductsColors.statGreen,
                  onTap: () => onSelected(ProductCategory.can),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : AddProductColors.fieldBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? accent : AddProductColors.labelGrey,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AddProductColors.titleNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddProductCanTypeSelector extends StatelessWidget {
  const AddProductCanTypeSelector({
    super.key,
    required this.isCool,
    required this.onChanged,
  });

  final bool isCool;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: _CanChip(
              label: 'Normal',
              selected: !isCool,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CanChip(
              label: 'Cool',
              selected: isCool,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanChip extends StatelessWidget {
  const _CanChip({
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
      color: selected ? ProductsColors.canBg : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? ProductsColors.statGreen
                  : AddProductColors.fieldBorder,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AddProductColors.titleNavy,
            ),
          ),
        ),
      ),
    );
  }
}

class AddProductQuantityField extends StatelessWidget {
  const AddProductQuantityField({
    super.key,
    required this.controller,
    required this.category,
    required this.isCool,
  });

  final TextEditingController controller;
  final ProductCategory category;
  final bool isCool;

  @override
  Widget build(BuildContext context) {
    if (category == ProductCategory.can) {
      return const SizedBox.shrink();
    }
    return AddEditCustomerField(
      label: 'Size / quantity',
      controller: controller,
      hint: 'e.g. 1 L, 2 L, 20 L',
      icon: Icons.straighten_outlined,
      required: true,
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Size is required' : null,
    );
  }
}

String? validateProductPrice(String? value) {
  if (value == null || value.trim().isEmpty) return 'Price is required';
  final parsed = double.tryParse(value.replaceAll(',', '').trim());
  if (parsed == null || parsed <= 0) return 'Enter a valid price';
  return null;
}

String? validateStockQty(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final n = int.tryParse(value.trim());
  if (n == null || n < 0) return 'Enter a valid quantity';
  return null;
}
