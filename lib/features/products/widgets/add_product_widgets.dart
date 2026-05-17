import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/services/product_image_service.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
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
    return AddEditCustomerHeader(title: 'Add Product', onBack: onBack);
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
    final file = ProductImageService.fileForPath(imagePath);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddProductColors.fieldBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: file != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(file, fit: BoxFit.cover),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: onRemove,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Material(
                      color: ProductsColors.bottleBg,
                      child: InkWell(
                        onTap: onPickCamera,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: ProductsColors.statBlue.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                size: 32,
                                color: ProductsColors.statBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add product photo',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ProductsColors.titleNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Take a clear photo from your shop',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AddProductColors.labelGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _PhotoActionButton(
                    icon: Icons.photo_camera_outlined,
                    label: 'Camera',
                    onTap: onPickCamera,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PhotoActionButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: onPickGallery,
                    outlined: true,
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

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: outlined ? Border.all(color: AddProductColors.fieldBorder) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: outlined ? ProductsColors.statBlue : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
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
            'Product type',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AddProductColors.labelGrey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TypeCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Bottles',
                  subtitle: '½ L, 1 L, 2 L, 25 L…',
                  selected: selected == ProductCategory.bottle,
                  onTap: () => onSelected(ProductCategory.bottle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeCard(
                  icon: Icons.local_drink_outlined,
                  title: 'Big Cans',
                  subtitle: 'Normal & Cool 20L',
                  selected: selected == ProductCategory.can,
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ProductsColors.bottleBg : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ProductsColors.statBlue : AddProductColors.fieldBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? ProductsColors.statBlue : AddProductColors.labelGrey,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AddProductColors.titleNavy,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 10, color: AddProductColors.labelGrey),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _CanChip(
              label: 'Normal Can',
              icon: Icons.water_drop_outlined,
              selected: !isCool,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CanChip(
              label: 'Cool Can',
              icon: Icons.ac_unit_rounded,
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ProductsColors.canBg : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? ProductsColors.statGreen : AddProductColors.fieldBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? ProductsColors.statGreen : AddProductColors.labelGrey),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

String? validateProductPrice(String? value) {
  if (value == null || value.trim().isEmpty) return 'Price is required';
  final parsed = double.tryParse(value.replaceAll(',', '').trim());
  if (parsed == null || parsed <= 0) return 'Enter a valid price';
  return null;
}
