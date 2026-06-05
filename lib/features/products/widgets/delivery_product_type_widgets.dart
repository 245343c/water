import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/models/product_icon_choice.dart';

abstract final class DeliveryTypeColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color iconBg = Color(0xFFEFF6FF);
  static const Color selectedBg = Color(0xFFF0F9FF);
  static const Color selectedBorder = Color(0xFF2563EB);
}

/// Shared grid sizing for fixed types and catalog cards (same box size).
SliverGridDelegate productTypeGridDelegate({bool compact = true}) {
  if (compact) {
    return const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 168,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.88,
    );
  }
  return const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 0.88,
  );
}

/// Grid of fixed delivery product type boxes (wireframe style).
class DeliveryProductTypeGrid extends StatelessWidget {
  const DeliveryProductTypeGrid({
    super.key,
    required this.types,
    required this.builder,
    this.compact = false,
  });

  final List<DeliveryProductType> types;
  final Widget Function(BuildContext context, DeliveryProductType type) builder;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: productTypeGridDelegate(compact: compact),
      itemCount: types.length,
      itemBuilder: (context, index) => builder(context, types[index]),
    );
  }
}

/// Styled product-type icon (wireframe blue box look).
class DeliveryTypeIcon extends StatelessWidget {
  const DeliveryTypeIcon({
    super.key,
    required this.type,
    this.size = 40,
    this.active = true,
    this.iconScale = 0.52,
  });

  final DeliveryProductType type;
  final double size;
  final bool active;
  /// Icon glyph size relative to container (box size unchanged).
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? DeliveryTypeColors.accentBlue
        : DeliveryTypeColors.labelGrey;
    final iconSize = size * iconScale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DeliveryTypeColors.iconBg,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: active
              ? DeliveryTypeColors.accentBlue.withValues(alpha: 0.2)
              : DeliveryTypeColors.cardBorder,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(type.icon, size: iconSize, color: color),
          if (type == DeliveryProductType.coolCan)
            Positioned(
              right: size * 0.12,
              bottom: size * 0.12,
              child: Icon(
                Icons.ac_unit_rounded,
                size: iconSize * 0.45,
                color: color,
              ),
            ),
          if (type == DeliveryProductType.autoCans)
            Positioned(
              right: size * 0.08,
              top: size * 0.08,
              child: Icon(
                Icons.water_drop_outlined,
                size: iconSize * 0.38,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

/// Section title on the page gradient (between white cards).
class ProductsGradientSectionTitle extends StatelessWidget {
  const ProductsGradientSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One product row — same card chrome as [CustomerListCard].
class ProductListCard extends StatelessWidget {
  const ProductListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rateText,
    required this.leading,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String rateText;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CustomersColors.cardBorder),
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
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DeliveryTypeColors.titleNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: DeliveryTypeColors.labelGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rateText,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: DeliveryTypeColors.accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DeliveryTypeColors.labelGrey,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeliveryProductTypeListCard extends StatelessWidget {
  const DeliveryProductTypeListCard({
    super.key,
    required this.type,
    required this.rateText,
    this.onTap,
  });

  final DeliveryProductType type;
  final String rateText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ProductListCard(
      title: type.title,
      subtitle: type.subtitle,
      rateText: rateText,
      onTap: onTap,
      leading: DeliveryTypeIcon(type: type, size: 48, iconScale: 0.55),
    );
  }
}

class CatalogProductListCard extends StatelessWidget {
  const CatalogProductListCard({
    super.key,
    required this.product,
    this.onTap,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = productIconByKey(product.iconKey).icon;

    return ProductListCard(
      title: product.name,
      subtitle: product.variantSummary,
      rateText: CurrencyUtils.format(product.startingPrice),
      onTap: onTap,
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: DeliveryTypeColors.iconBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DeliveryTypeColors.cardBorder),
        ),
        child: Icon(icon, size: 28, color: DeliveryTypeColors.accentBlue),
      ),
    );
  }
}

class DeliveryProductTypeBox extends StatelessWidget {
  const DeliveryProductTypeBox({
    super.key,
    required this.type,
    this.selected = false,
    this.enabled = true,
    this.rateText,
    this.onTap,
    this.compact = false,
    this.emphasized = false,
  });

  final DeliveryProductType type;
  final bool selected;
  final bool enabled;
  final String? rateText;
  final VoidCallback? onTap;
  final bool compact;
  /// Larger labels/icons inside the same grid cell (Products page).
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final isActive = selected || enabled;
    final iconSize = compact ? 36.0 : 44.0;
    final titleSize = emphasized ? 13.0 : (compact ? 11.0 : 12.0);
    final subtitleSize = emphasized ? 10.0 : (compact ? 9.0 : 10.0);
    final rateSize = emphasized ? 12.0 : (compact ? 9.0 : 10.0);
    final iconScale = emphasized ? 0.62 : 0.52;

    return _UnifiedTypeCard(
      selected: selected,
      enabled: enabled,
      compact: compact,
      onTap: onTap,
      icon: DeliveryTypeIcon(
        type: type,
        size: iconSize,
        active: isActive,
        iconScale: iconScale,
      ),
      title: type.title,
      subtitle: type.subtitle,
      rateText: rateText,
      titleSize: titleSize,
      subtitleSize: subtitleSize,
      rateSize: rateSize,
      isActive: isActive,
    );
  }
}

class CatalogProductCardBox extends StatelessWidget {
  const CatalogProductCardBox({
    super.key,
    required this.product,
    this.onTap,
    this.compact = true,
    this.emphasized = false,
  });

  final Product product;
  final VoidCallback? onTap;
  final bool compact;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final icon = productIconByKey(product.iconKey).icon;
    final box = compact ? 36.0 : 44.0;
    final glyph = emphasized ? 24.0 : (compact ? 18.0 : 22.0);
    return _UnifiedTypeCard(
      selected: false,
      enabled: true,
      compact: compact,
      onTap: onTap,
      icon: Container(
        width: box,
        height: box,
        decoration: BoxDecoration(
          color: DeliveryTypeColors.iconBg,
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          border: Border.all(color: DeliveryTypeColors.cardBorder),
        ),
        child: Icon(icon, size: glyph, color: DeliveryTypeColors.accentBlue),
      ),
      title: product.name,
      subtitle: product.variantSummary,
      rateText: CurrencyUtils.format(product.startingPrice),
      titleSize: emphasized ? 13 : (compact ? 11 : 12),
      subtitleSize: emphasized ? 10 : (compact ? 9 : 10),
      rateSize: emphasized ? 12 : (compact ? 10 : 11),
      isActive: true,
    );
  }
}

class _UnifiedTypeCard extends StatelessWidget {
  const _UnifiedTypeCard({
    required this.selected,
    required this.enabled,
    required this.compact,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.rateText,
    required this.titleSize,
    required this.subtitleSize,
    required this.rateSize,
    required this.isActive,
  });

  final bool selected;
  final bool enabled;
  final bool compact;
  final VoidCallback? onTap;
  final Widget icon;
  final String title;
  final String subtitle;
  final String? rateText;
  final double titleSize;
  final double subtitleSize;
  final double rateSize;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? DeliveryTypeColors.selectedBorder : DeliveryTypeColors.cardBorder;
    final bg = selected
        ? DeliveryTypeColors.selectedBg
        : (enabled ? Colors.white : const Color(0xFFF9FAFB));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(compact ? 12 : 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 8,
            vertical: compact ? 6 : 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(height: compact ? 4 : 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: isActive
                      ? DeliveryTypeColors.titleNavy
                      : DeliveryTypeColors.labelGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '($subtitle)',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: subtitleSize,
                  height: 1.2,
                  color: DeliveryTypeColors.labelGrey,
                ),
              ),
              if (rateText != null) ...[
                SizedBox(height: compact ? 3 : 4),
                Text(
                  rateText!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: rateSize,
                    fontWeight: FontWeight.w700,
                    color: DeliveryTypeColors.accentBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Builds separated list cards for the Products screen (Customers-style layout).
List<Widget> buildProductsListChildren({
  required double Function(DeliveryProductType type) rateFor,
  required void Function(DeliveryProductType type, double currentRate) onEditRate,
  required List<Product> catalogProducts,
  void Function(Product product)? onEditCatalogProduct,
  String query = '',
}) {
  final q = query.trim().toLowerCase();
  bool matches(String title, String subtitle, String rate) {
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        subtitle.toLowerCase().contains(q) ||
        rate.toLowerCase().contains(q);
  }

  final children = <Widget>[
    const ProductsGradientSectionTitle(
      title: 'Delivery types',
      subtitle: 'Tap a card to set shop default rate',
    ),
  ];

  var typeCount = 0;
  for (final type in DeliveryProductType.catalog) {
    final rate = rateFor(type);
    final rateLabel = rate > 0
        ? '${CurrencyUtils.format(rate)} ${type.rateLabel}'
        : 'Set rate';
    if (!matches(type.title, type.subtitle, rateLabel)) continue;
    typeCount++;
    children.add(
      DeliveryProductTypeListCard(
        type: type,
        rateText: rateLabel,
        onTap: () => onEditRate(type, rate),
      ),
    );
  }

  final filteredCatalog = catalogProducts.where((p) {
    final rate = CurrencyUtils.format(p.startingPrice);
    return matches(p.name, p.variantSummary, rate);
  }).toList();

  if (filteredCatalog.isNotEmpty) {
    children.add(
      const ProductsGradientSectionTitle(
        title: 'Bottle catalog',
        subtitle: 'Extra sizes for your shop',
      ),
    );
    final onEditCatalog = onEditCatalogProduct;
    for (final product in filteredCatalog) {
      children.add(
        CatalogProductListCard(
          product: product,
          onTap: onEditCatalog == null
              ? null
              : () => onEditCatalog(product),
        ),
      );
    }
  }

  if (typeCount == 0 && filteredCatalog.isEmpty && q.isNotEmpty) {
    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No products match your search',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: DeliveryTypeColors.labelGrey,
            ),
          ),
        ),
      ),
    );
  }

  return children;
}

/// Fixed bottom-right control to add a catalog product (Products page).
class ProductsAddProductButton extends StatelessWidget {
  const ProductsAddProductButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      shadowColor: const Color(0xFF1A73E8).withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFF1A73E8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Text(
                'Add product',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<double?> showDeliveryTypeRateDialog(
  BuildContext context, {
  required DeliveryProductType type,
  required double currentRate,
}) async {
  var input = currentRate > 0 ? currentRate.toStringAsFixed(0) : '';
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        type.title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop default rate (${type.rateLabel})',
            style: GoogleFonts.poppins(fontSize: 12, color: DeliveryTypeColors.labelGrey),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: input,
            onChanged: (value) => input = value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: () {
            final parsed = double.tryParse(input.replaceAll(',', '').trim());
            if (parsed == null || parsed < 0) return;
            Navigator.pop(ctx, parsed);
          },
          child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
  return result;
}

class CatalogProductDialogResult {
  const CatalogProductDialogResult._({this.updatedPrice, this.delete = false});

  final double? updatedPrice;
  final bool delete;

  factory CatalogProductDialogResult.update(double price) =>
      CatalogProductDialogResult._(updatedPrice: price);
  factory CatalogProductDialogResult.delete() =>
      const CatalogProductDialogResult._(delete: true);
}

Future<CatalogProductDialogResult?> showCatalogProductDialog(
  BuildContext context, {
  required Product product,
}) async {
  var input =
      product.startingPrice > 0 ? product.startingPrice.toStringAsFixed(0) : '';
  return showDialog<CatalogProductDialogResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      title: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(ctx, CatalogProductDialogResult.delete()),
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Delete product',
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop default rate',
            style: GoogleFonts.poppins(fontSize: 12, color: DeliveryTypeColors.labelGrey),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: input,
            onChanged: (value) => input = value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              prefixText: '₹ ',
              hintText: '0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        FilledButton(
          onPressed: () {
            final parsed = double.tryParse(input.replaceAll(',', '').trim());
            if (parsed == null || parsed < 0) return;
            Navigator.pop(ctx, CatalogProductDialogResult.update(parsed));
          },
          child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
