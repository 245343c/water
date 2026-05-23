import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/constants/customer_pricing_keys.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';

/// Editable pricing list for Add / Edit Customer.
class CustomerPricingEditor extends StatefulWidget {
  const CustomerPricingEditor({
    super.key,
    required this.repo,
    required this.entries,
    required this.onChanged,
    this.embedded = false,
  });

  final WaterPlantRepository repo;
  final List<CustomerProductPrice> entries;
  final ValueChanged<List<CustomerProductPrice>> onChanged;
  /// When true, renders inside the customer details form card (no outer section title).
  final bool embedded;

  @override
  State<CustomerPricingEditor> createState() => _CustomerPricingEditorState();
}

class _CustomerPricingEditorState extends State<CustomerPricingEditor> {
  late List<CustomerProductPrice> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<CustomerProductPrice>.from(widget.entries);
  }

  @override
  void didUpdateWidget(CustomerPricingEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _entries = List<CustomerProductPrice>.from(widget.entries);
    }
  }

  void _emit() => widget.onChanged(List<CustomerProductPrice>.from(_entries));

  CustomerProductPrice? _find(String productId, String variantId) {
    final key = '$productId|$variantId';
    for (final e in _entries) {
      if (e.key == key) return e;
    }
    return null;
  }

  void _upsert(CustomerProductPrice entry) {
    final key = entry.key;
    _entries.removeWhere((e) => e.key == key);
    _entries.add(entry);
    _emit();
    setState(() {});
  }

  void _setCanEnabled(String variantId, bool enabled) {
    final existing = _find(CustomerPricingKeys.canProductId, variantId);
    final price = existing?.unitPrice ??
        (variantId == CustomerPricingKeys.normalVariantId
            ? widget.repo.settings.normalPrice
            : widget.repo.settings.coolPrice);
    _upsert(
      CustomerProductPrice(
        productId: CustomerPricingKeys.canProductId,
        variantId: variantId,
        unitPrice: price,
        enabled: enabled,
      ),
    );
  }

  void _setCanPrice(String variantId, double price) {
    final existing = _find(CustomerPricingKeys.canProductId, variantId);
    _upsert(
      CustomerProductPrice(
        productId: CustomerPricingKeys.canProductId,
        variantId: variantId,
        unitPrice: price,
        enabled: existing?.enabled ?? true,
      ),
    );
  }

  void _addBottleProduct(Product product) {
    for (final variant in product.variants) {
      if (_find(product.id, variant.id) != null) continue;
      _upsert(
        CustomerProductPrice(
          productId: product.id,
          variantId: variant.id,
          unitPrice: variant.price,
          enabled: true,
        ),
      );
    }
  }

  void _removeBottleProduct(String productId) {
    _entries.removeWhere((e) => e.productId == productId);
    _emit();
    setState(() {});
  }

  void _setBottlePrice(String productId, String variantId, double price) {
    final existing = _find(productId, variantId);
    _upsert(
      CustomerProductPrice(
        productId: productId,
        variantId: variantId,
        unitPrice: price,
        enabled: existing?.enabled ?? true,
      ),
    );
  }

  void _setBottleEnabled(String productId, String variantId, bool enabled) {
    final existing = _find(productId, variantId);
    if (existing == null) return;
    _upsert(existing.copyWith(enabled: enabled));
  }

  void _resetToShopRates() {
    setState(() => _entries = widget.repo.defaultCustomerPricing());
    _emit();
  }

  List<Product> get _bottleProductsInEntries {
    final ids = _entries.map((e) => e.productId).toSet();
    return widget.repo.products
        .where((p) => p.category == ProductCategory.bottle && ids.contains(p.id))
        .toList();
  }

  List<Product> get _availableToAdd {
    final added = _entries.map((e) => e.productId).toSet();
    return widget.repo.products
        .where(
          (p) =>
              p.isActive &&
              p.category == ProductCategory.bottle &&
              !added.contains(p.id),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final normalEntry = _find(
      CustomerPricingKeys.canProductId,
      CustomerPricingKeys.normalVariantId,
    );
    final coolEntry = _find(
      CustomerPricingKeys.canProductId,
      CustomerPricingKeys.coolVariantId,
    );

    final hPad = widget.embedded ? 16.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer assigned rates',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AddEditCustomerColors.labelGrey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'These rates are used by admin, driver, and customer app',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AddEditCustomerColors.labelGrey.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetToShopRates,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    'Default rates',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AddEditCustomerColors.primaryBtn,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Column(
            children: [
        _CanPricingCard(
          embedded: widget.embedded,
          normalEnabled: normalEntry?.enabled ?? true,
          coolEnabled: coolEntry?.enabled ?? true,
          normalPrice: normalEntry?.unitPrice ?? widget.repo.settings.normalPrice,
          coolPrice: coolEntry?.unitPrice ?? widget.repo.settings.coolPrice,
          shopNormal: widget.repo.settings.normalPrice,
          shopCool: widget.repo.settings.coolPrice,
          onNormalEnabled: (v) => _setCanEnabled(CustomerPricingKeys.normalVariantId, v),
          onCoolEnabled: (v) => _setCanEnabled(CustomerPricingKeys.coolVariantId, v),
          onNormalPrice: (v) => _setCanPrice(CustomerPricingKeys.normalVariantId, v),
          onCoolPrice: (v) => _setCanPrice(CustomerPricingKeys.coolVariantId, v),
        ),
        ..._bottleProductsInEntries.map((product) {
          final variantEntries = product.variants
              .map((v) => _find(product.id, v.id))
              .whereType<CustomerProductPrice>()
              .toList();
          return _BottlePricingCard(
            product: product,
            entries: variantEntries,
            embedded: widget.embedded,
            onRemove: () => _removeBottleProduct(product.id),
            onPriceChanged: (variantId, price) =>
                _setBottlePrice(product.id, variantId, price),
            onEnabledChanged: (variantId, enabled) =>
                _setBottleEnabled(product.id, variantId, enabled),
          );
        }),
        if (_availableToAdd.isNotEmpty)
          _AddProductDropdown(
            products: _availableToAdd,
            embedded: widget.embedded,
            onSelected: _addBottleProduct,
          ),
        if (widget.repo.products.where((p) => p.category == ProductCategory.bottle).isEmpty)
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AddEditCustomerColors.fieldBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AddEditCustomerColors.labelGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add bottle products in Products tab to assign custom bottle prices.',
                      style: GoogleFonts.poppins(fontSize: 11, height: 1.35, color: AddEditCustomerColors.labelGrey),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
        SizedBox(height: widget.embedded ? 4 : 8),
      ],
    );
  }
}

class _CanPricingCard extends StatelessWidget {
  const _CanPricingCard({
    required this.normalEnabled,
    required this.coolEnabled,
    required this.normalPrice,
    required this.coolPrice,
    required this.shopNormal,
    required this.shopCool,
    required this.onNormalEnabled,
    required this.onCoolEnabled,
    required this.onNormalPrice,
    required this.onCoolPrice,
    this.embedded = false,
  });

  final bool normalEnabled;
  final bool coolEnabled;
  final double normalPrice;
  final double coolPrice;
  final double shopNormal;
  final double shopCool;
  final ValueChanged<bool> onNormalEnabled;
  final ValueChanged<bool> onCoolEnabled;
  final ValueChanged<double> onNormalPrice;
  final ValueChanged<double> onCoolPrice;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _PricingCardShell(
      embedded: embedded,
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF2563EB),
      title: '20L water cans',
      subtitle: 'Assign this customer normal and cool can rates',
      child: Column(
        children: [
          _VariantPriceRow(
            label: 'Normal Can',
            enabled: normalEnabled,
            price: normalPrice,
            shopHint: shopNormal,
            onEnabled: onNormalEnabled,
            onPrice: onNormalPrice,
          ),
          const SizedBox(height: 10),
          _VariantPriceRow(
            label: 'Cool Can',
            enabled: coolEnabled,
            price: coolPrice,
            shopHint: shopCool,
            onEnabled: onCoolEnabled,
            onPrice: onCoolPrice,
          ),
        ],
      ),
    );
  }
}

class _BottlePricingCard extends StatelessWidget {
  const _BottlePricingCard({
    required this.product,
    required this.entries,
    required this.onRemove,
    required this.onPriceChanged,
    required this.onEnabledChanged,
    this.embedded = false,
  });

  final Product product;
  final List<CustomerProductPrice> entries;
  final VoidCallback onRemove;
  final void Function(String variantId, double price) onPriceChanged;
  final void Function(String variantId, bool enabled) onEnabledChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _PricingCardShell(
      embedded: embedded,
      icon: Icons.local_drink_outlined,
      iconColor: const Color(0xFF0D9488),
      title: product.name,
      subtitle: product.variantSummary,
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9CA3AF)),
        onPressed: onRemove,
        tooltip: 'Remove product',
      ),
      child: Column(
        children: [
          for (final entry in entries) ...[
            _VariantPriceRow(
              label: product.variants.firstWhere((v) => v.id == entry.variantId).label,
              enabled: entry.enabled,
              price: entry.unitPrice,
              shopHint: product.variants.firstWhere((v) => v.id == entry.variantId).price,
              onEnabled: (v) => onEnabledChanged(entry.variantId, v),
              onPrice: (v) => onPriceChanged(entry.variantId, v),
            ),
            if (entry != entries.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PricingCardShell extends StatelessWidget {
  const _PricingCardShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    this.embedded = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: embedded ? 10 : 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
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
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(fontSize: 11, color: AddEditCustomerColors.labelGrey),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _VariantPriceRow extends StatelessWidget {
  const _VariantPriceRow({
    required this.label,
    required this.enabled,
    required this.price,
    required this.shopHint,
    required this.onEnabled,
    required this.onPrice,
  });

  final String label;
  final bool enabled;
  final double price;
  final double shopHint;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<double> onPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? const Color(0xFFBFDBFE) : AddEditCustomerColors.fieldBorder,
        ),
      ),
      child: Row(
        children: [
          Switch.adaptive(
            value: enabled,
            onChanged: onEnabled,
            activeTrackColor: AddEditCustomerColors.primaryBtn.withValues(alpha: 0.5),
            activeThumbColor: AddEditCustomerColors.primaryBtn,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: enabled ? const Color(0xFF111827) : AddEditCustomerColors.labelGrey,
                  ),
                ),
                Text(
                  'Default: ${CurrencyUtils.format(shopHint)}',
                  style: GoogleFonts.poppins(fontSize: 10, color: AddEditCustomerColors.labelGrey),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 88,
            child: _PriceField(
              value: price,
              enabled: enabled,
              onChanged: onPrice,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceField extends StatefulWidget {
  const _PriceField({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  State<_PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<_PriceField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(_PriceField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = _format(widget.value);
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  String _format(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E3A8A),
      ),
      decoration: InputDecoration(
        prefixText: '₹ ',
        prefixStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: widget.enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AddEditCustomerColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AddEditCustomerColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AddEditCustomerColors.primaryBtn, width: 1.5),
        ),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text.trim());
        if (parsed != null && parsed >= 0) widget.onChanged(parsed);
      },
    );
  }
}

class _AddProductDropdown extends StatelessWidget {
  const _AddProductDropdown({
    required this.products,
    required this.onSelected,
    this.embedded = false,
  });

  final List<Product> products;
  final ValueChanged<Product> onSelected;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: embedded ? 8 : 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AddEditCustomerColors.fieldBorder, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Product>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: AddEditCustomerColors.primaryBtn),
              const SizedBox(width: 10),
              Text(
                'Add bottle product',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AddEditCustomerColors.primaryBtn,
                ),
              ),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AddEditCustomerColors.primaryBtn),
          items: products
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              )
              .toList(),
          onChanged: (p) {
            if (p != null) onSelected(p);
          },
        ),
      ),
    );
  }
}
