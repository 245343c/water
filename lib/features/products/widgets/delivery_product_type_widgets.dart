import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
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
  });

  final DeliveryProductType type;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? DeliveryTypeColors.accentBlue
        : DeliveryTypeColors.labelGrey;
    final iconSize = size * 0.52;

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

class DeliveryProductTypeBox extends StatelessWidget {
  const DeliveryProductTypeBox({
    super.key,
    required this.type,
    this.selected = false,
    this.enabled = true,
    this.rateText,
    this.onTap,
    this.compact = false,
  });

  final DeliveryProductType type;
  final bool selected;
  final bool enabled;
  final String? rateText;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isActive = selected || enabled;
    final iconSize = compact ? 36.0 : 44.0;
    final titleSize = compact ? 11.0 : 12.0;
    final subtitleSize = compact ? 9.0 : 10.0;
    final rateSize = compact ? 9.0 : 10.0;

    return _UnifiedTypeCard(
      selected: selected,
      enabled: enabled,
      compact: compact,
      onTap: onTap,
      icon: DeliveryTypeIcon(
        type: type,
        size: iconSize,
        active: isActive,
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
  });

  final Product product;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = productIconByKey(product.iconKey).icon;
    return _UnifiedTypeCard(
      selected: false,
      enabled: true,
      compact: compact,
      onTap: onTap,
      icon: Container(
        width: compact ? 36 : 44,
        height: compact ? 36 : 44,
        decoration: BoxDecoration(
          color: DeliveryTypeColors.iconBg,
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          border: Border.all(color: DeliveryTypeColors.cardBorder),
        ),
        child: Icon(icon, size: compact ? 18 : 22, color: DeliveryTypeColors.accentBlue),
      ),
      title: product.name,
      subtitle: product.variantSummary,
      rateText: CurrencyUtils.format(product.startingPrice),
      titleSize: compact ? 11 : 12,
      subtitleSize: compact ? 9 : 10,
      rateSize: compact ? 10 : 11,
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
            vertical: compact ? 8 : 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(height: compact ? 6 : 8),
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

/// Fixed catalog on Products — shop default rates, tap to edit.
class ProductsDeliveryTypesSection extends StatelessWidget {
  const ProductsDeliveryTypesSection({
    super.key,
    required this.rateFor,
    required this.onEditRate,
    this.catalogProducts = const [],
    this.onEditCatalogProduct,
    this.compact = true,
  });

  final double Function(DeliveryProductType type) rateFor;
  final void Function(DeliveryProductType type, double currentRate) onEditRate;
  final List<Product> catalogProducts;
  final void Function(Product product)? onEditCatalogProduct;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeliveryTypeColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery product types',
            style: GoogleFonts.poppins(
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w800,
              color: DeliveryTypeColors.titleNavy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Tap a type to set shop default rate. Enable per customer when adding them.',
            style: GoogleFonts.poppins(
              fontSize: compact ? 10 : 11,
              height: 1.35,
              color: DeliveryTypeColors.labelGrey,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          DeliveryProductTypeGrid(
            compact: compact,
            types: DeliveryProductType.catalog,
            builder: (context, type) {
              final rate = rateFor(type);
              final rateLabel = rate > 0
                  ? '${CurrencyUtils.format(rate)} ${type.rateLabel}'
                  : 'Set rate';
              return DeliveryProductTypeBox(
                type: type,
                compact: compact,
                rateText: rateLabel,
                onTap: () => onEditRate(type, rate),
              );
            },
          ),
          if (catalogProducts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catalog',
              style: GoogleFonts.poppins(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: DeliveryTypeColors.labelGrey,
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: catalogProducts.length,
              gridDelegate: productTypeGridDelegate(compact: compact),
              itemBuilder: (context, i) {
                final product = catalogProducts[i];
                return CatalogProductCardBox(
                  product: product,
                  compact: compact,
                  onTap: onEditCatalogProduct == null
                      ? null
                      : () => onEditCatalogProduct!(product),
                );
              },
            ),
          ],
        ],
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
