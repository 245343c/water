import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/models/product_variant.dart';
import 'package:sri_sai_ro_water/data/models/product_variant.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/core/services/product_image_service.dart';

abstract final class ProductsColors {
  static const Color titleNavy = Color(0xFF1E3A8A);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color statBlue = Color(0xFF2563EB);
  static const Color statGreen = Color(0xFF16A34A);
  static const Color coolAccent = Color(0xFF0EA5E9);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color bottleBg = Color(0xFFEFF6FF);
  static const Color canBg = Color(0xFFECFDF5);
}

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.product,
    this.size = 56,
    this.radius = 14,
  });

  final Product product;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final file = ProductImageService.fileForPath(product.localImagePath);
    final isBottle = product.category == ProductCategory.bottle;
    final accentBg = isBottle ? ProductsColors.bottleBg : ProductsColors.canBg;
    final accentColor = isBottle ? ProductsColors.statBlue : ProductsColors.statGreen;
    final icon = isBottle ? Icons.water_drop_outlined : Icons.local_drink_outlined;

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

class ProductCategoryChip extends StatelessWidget {
  const ProductCategoryChip({
    super.key,
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
      color: selected ? CustomersColors.addButton : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class ProductListCard extends StatelessWidget {
  const ProductListCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBottle = product.category == ProductCategory.bottle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ProductsColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumbnail(product: product, size: 56, radius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: ProductsColors.titleNavy,
                              ),
                            ),
                          ),
                          _CategoryBadge(category: product.category),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.35,
                          color: ProductsColors.labelGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final v in product.variants)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _VariantRow(variant: v),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            'From ${CurrencyUtils.format(product.startingPrice)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isBottle ? ProductsColors.statBlue : ProductsColors.statGreen,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${product.variants.length} options',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: ProductsColors.labelGrey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 20, color: ProductsColors.labelGrey.withValues(alpha: 0.7)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    final isBottle = category == ProductCategory.bottle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

class _VariantRow extends StatelessWidget {
  const _VariantRow({required this.variant});

  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: variant.isCool ? ProductsColors.coolAccent.withValues(alpha: 0.08) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ProductsColors.cardBorder),
      ),
      child: Row(
        children: [
          if (variant.isCool)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.ac_unit_rounded, size: 16, color: ProductsColors.coolAccent),
            ),
          Expanded(
            child: Text(
              variant.label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ProductsColors.titleNavy,
              ),
            ),
          ),
          Text(
            CurrencyUtils.format(variant.price),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ProductsColors.statGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailHeader extends StatelessWidget {
  const ProductDetailHeader({super.key, required this.onBack});

  final VoidCallback onBack;

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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class ProductDetailHero extends StatelessWidget {
  const ProductDetailHero({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final isBottle = product.category == ProductCategory.bottle;
    final accentColor = isBottle ? ProductsColors.statBlue : ProductsColors.statGreen;
    final file = ProductImageService.fileForPath(product.localImagePath);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProductsColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (file != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(file, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (file == null) ...[
                  ProductThumbnail(product: product, size: 72, radius: 16),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ProductsColors.titleNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category.label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.4,
                          color: ProductsColors.labelGrey,
                        ),
                      ),
                    ],
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

class ProductVariantRow extends StatelessWidget {
  const ProductVariantRow({super.key, required this.variant});

  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ProductsColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: variant.isCool
                  ? ProductsColors.coolAccent.withValues(alpha: 0.12)
                  : ProductsColors.bottleBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              variant.isCool ? Icons.ac_unit_rounded : Icons.water_drop_outlined,
              color: variant.isCool ? ProductsColors.coolAccent : ProductsColors.statBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              variant.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ProductsColors.titleNavy,
              ),
            ),
          ),
          Text(
            CurrencyUtils.format(variant.price),
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: ProductsColors.statGreen,
            ),
          ),
        ],
      ),
    );
  }
}
