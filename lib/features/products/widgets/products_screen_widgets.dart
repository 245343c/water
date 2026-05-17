import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/core/services/product_image_service.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/models/product_variant.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class ProductsColors {
  static const Color titleNavy = Color(0xFF1E3A8A);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color coolAccent = Color(0xFF0EA5E9);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color bottleBg = Color(0xFFEFF6FF);
  static const Color canBg = Color(0xFFECFDF5);
  static const Color coolBg = Color(0xFFE0F2FE);
  static const Color screenBg = Color(0xFFF3F4F6);
}

// ─── Scaffold ────────────────────────────────────────────────────────────────

class ProductsScaffold extends StatelessWidget {
  const ProductsScaffold({super.key, required this.child});
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

// ─── Category filter chip ─────────────────────────────────────────────────────

class ProductCategoryChip extends StatelessWidget {
  const ProductCategoryChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CustomersColors.addButton : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: ProductsColors.cardBorder),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : ProductsColors.labelGrey,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Product section — icon grid style, no header bar ────────────────────────
//
// Layout:
//   Product name (simple text label)
//   Grid of variant icon tiles — each tile: circle icon + label + price pill
//

class ProductSection extends StatelessWidget {
  const ProductSection({super.key, required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  bool get _isBottle => product.category == ProductCategory.bottle;
  int get _columns => _isBottle ? 3 : 2;
  Color get _accent =>
      _isBottle ? ProductsColors.statBlue : ProductsColors.statGreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Simple section title (no bar, no card) ─────────────────────
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ProductsColors.titleNavy,
                  ),
                ),
              ),
              _CategoryBadge(category: product.category),
            ],
          ),
          const SizedBox(height: 10),

          // ── Icon grid ──────────────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: product.variants.length,
            itemBuilder: (_, i) => _VariantIconTile(
              variant: product.variants[i],
              product: product,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Variant icon tile (icon + label + price) — no heavy box ─────────────────

class _VariantIconTile extends StatelessWidget {
  const _VariantIconTile({
    required this.variant,
    required this.product,
    required this.onTap,
  });
  final ProductVariant variant;
  final Product product;
  final VoidCallback onTap;

  bool get _isBottle => product.category == ProductCategory.bottle;
  bool get _isCool   => variant.isCool;

  Color get _accent {
    if (_isCool) return ProductsColors.coolAccent;
    if (_isBottle) return ProductsColors.statBlue;
    return ProductsColors.statGreen;
  }

  Color get _bgColor {
    if (_isCool) return ProductsColors.coolBg;
    if (_isBottle) return ProductsColors.bottleBg;
    return ProductsColors.canBg;
  }

  IconData get _icon {
    if (_isCool) return Icons.ac_unit_rounded;
    if (_isBottle) return Icons.water_drop_rounded;
    return Icons.water_drop_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final file = ProductImageService.fileForPath(product.localImagePath);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _accent.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Icon circle ──────────────────────────────────────────
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _bgColor,
                  shape: BoxShape.circle,
                ),
                child: file != null && _isBottle
                    ? ClipOval(
                        child: Image.file(file, fit: BoxFit.cover),
                      )
                    : Icon(_icon, color: _accent, size: 30),
              ),

              const SizedBox(height: 10),

              // ── Variant label ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  variant.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ProductsColors.titleNavy,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 6),

              // ── Price pill ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  CurrencyUtils.format(variant.price),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Product icon (for section header) ───────────────────────────────────────


// ─── Legacy ProductThumbnail (used by product detail screen) ──────────────────

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({super.key, required this.product, this.size = 56, this.radius = 14});
  final Product product;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final file = ProductImageService.fileForPath(product.localImagePath);
    final isBottle = product.category == ProductCategory.bottle;
    final accentBg = isBottle ? ProductsColors.bottleBg : ProductsColors.canBg;
    final accentColor = isBottle ? ProductsColors.statBlue : ProductsColors.statGreen;
    final icon = isBottle ? Icons.water_drop : Icons.local_drink_outlined;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        color: accentBg,
        child: file != null
            ? Image.file(file, fit: BoxFit.cover)
            : Icon(icon, color: accentColor, size: size * 0.5),
      ),
    );
  }
}

// ─── Category badge ───────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    final isBottle = category == ProductCategory.bottle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isBottle ? ProductsColors.statBlue : ProductsColors.statGreen).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category.label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isBottle ? ProductsColors.statBlue : ProductsColors.statGreen,
        ),
      ),
    );
  }
}

// ─── Product detail screen widgets ───────────────────────────────────────────

class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({
    super.key,
    required this.onBack,
    this.onDelete,
  });
  final VoidCallback onBack;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(4, MediaQuery.paddingOf(context).top + 4, 8, 14),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Product Details',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
              tooltip: 'Delete product',
              onPressed: onDelete,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class ProductDetailCard extends StatelessWidget {
  const ProductDetailCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final isBottle = product.category == ProductCategory.bottle;
    final accent = isBottle ? ProductsColors.statBlue : ProductsColors.statGreen;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProductsColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumbnail(product: product, size: 64, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: ProductsColors.titleNavy),
                        ),
                      ),
                      _CategoryBadge(category: product.category),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      product.description,
                      style: GoogleFonts.poppins(fontSize: 12, color: ProductsColors.labelGrey, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: ProductsColors.cardBorder),
          const SizedBox(height: 12),
          Text(
            '${product.variants.length} Size${product.variants.length == 1 ? '' : 's'} Available',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ProductsColors.labelGrey,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isBottle ? 3 : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: product.variants.length,
            itemBuilder: (_, i) => _VariantIconTile(
              variant: product.variants[i],
              product: product,
              onTap: () {},
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: accent.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'Starting from ${CurrencyUtils.format(product.startingPrice)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
