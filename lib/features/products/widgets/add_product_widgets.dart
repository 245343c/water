import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/app_image.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
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
      subtitle: 'Catalog item and default rate',
      onBack: onBack,
    );
  }
}

/// Live preview of what will be saved.
class AddProductLivePreview extends StatelessWidget {
  const AddProductLivePreview({
    super.key,
    required this.name,
    required this.sizeLabel,
    required this.priceText,
    required this.category,
    required this.isCool,
    this.imagePath,
  });

  final String name;
  final String sizeLabel;
  final String priceText;
  final ProductCategory category;
  final bool isCool;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final isBottle = category == ProductCategory.bottle;
    final accent = isCool
        ? ProductsColors.coolAccent
        : (isBottle ? ProductsColors.statBlue : ProductsColors.statGreen);
    final price = double.tryParse(priceText.replaceAll(',', '').trim());
    final displayName = name.trim().isEmpty ? 'Product name' : name.trim();
    final displaySize = sizeLabel.trim().isEmpty
        ? (isBottle ? 'Size' : (isCool ? 'Cool can' : 'Normal can'))
        : sizeLabel.trim();
    final placeholder = ColoredBox(
      color: accent.withValues(alpha: 0.1),
      child: Icon(
        isBottle ? Icons.water_drop_rounded : Icons.local_drink_rounded,
        color: accent,
        size: 32,
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: AppImage(
                path: imagePath,
                placeholder: placeholder,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AddProductColors.labelGrey,
                  ),
                ),
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AddProductColors.titleNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  displaySize,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AddProductColors.labelGrey,
                  ),
                ),
                Text(
                  price != null
                      ? 'Default ${CurrencyUtils.format(price)}'
                      : 'Default rate',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddProductPhotoSection extends StatelessWidget {
  const AddProductPhotoSection({
    super.key,
    required this.imagePath,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHOTO',
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
              GestureDetector(
                onTap: onPickCamera,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: AppImage(
                      path: imagePath,
                      placeholder: const ColoredBox(
                        color: ProductsColors.bottleBg,
                        child: Icon(Icons.add_a_photo_outlined, color: ProductsColors.statBlue),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PhotoBtn(
                      icon: Icons.photo_camera_outlined,
                      label: 'Camera',
                      onTap: onPickCamera,
                    ),
                    const SizedBox(height: 8),
                    _PhotoBtn(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: onPickGallery,
                      outlined: true,
                    ),
                  ],
                ),
              ),
              if (imagePath != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AddProductColors.labelGrey,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoBtn extends StatelessWidget {
  const _PhotoBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.white : AddProductColors.primaryBtn,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: outlined
                ? Border.all(color: AddProductColors.fieldBorder)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: outlined ? ProductsColors.statBlue : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: outlined ? ProductsColors.statBlue : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : AddProductColors.fieldBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? accent : AddProductColors.labelGrey),
              const SizedBox(height: 4),
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
