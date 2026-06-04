import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/delivery_product_type.dart';
import 'package:sri_sai_ro_water/data/models/customer_product_price.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/products/models/product_icon_choice.dart';
import 'package:sri_sai_ro_water/features/products/widgets/delivery_product_type_widgets.dart';

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

  void _setDeliveryTypeEnabled(DeliveryProductType type, bool enabled) {
    final existing = _find(type.productId, type.variantId);
    final price =
        existing?.unitPrice ?? widget.repo.shopDefaultRateForDeliveryType(type);
    _upsert(
      CustomerProductPrice(
        productId: type.productId,
        variantId: type.variantId,
        unitPrice: price,
        enabled: enabled,
      ),
    );
  }

  void _setDeliveryTypePrice(DeliveryProductType type, double price) {
    final existing = _find(type.productId, type.variantId);
    _upsert(
      CustomerProductPrice(
        productId: type.productId,
        variantId: type.variantId,
        unitPrice: price,
        enabled: existing?.enabled ?? false,
      ),
    );
  }

  bool _isDeliveryTypeEnabled(DeliveryProductType type) {
    return _find(type.productId, type.variantId)?.enabled ?? false;
  }

  double _deliveryTypePrice(DeliveryProductType type) {
    return _find(type.productId, type.variantId)?.unitPrice ??
        widget.repo.shopDefaultRateForDeliveryType(type);
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
        enabled: existing?.enabled ?? false,
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

  List<_CustomerSelectableItem> _allSelectableItems() {
    final list = <_CustomerSelectableItem>[
      for (final type in DeliveryProductType.catalog)
        _CustomerSelectableItem(
          productId: type.productId,
          variantId: type.variantId,
          title: type.title,
          subtitle: type.subtitle,
          icon: type.icon,
          shopRate: widget.repo.shopDefaultRateForDeliveryType(type),
          enabled: _isDeliveryTypeEnabled(type),
          currentRate: _deliveryTypePrice(type),
        ),
    ];

    for (final product in widget.repo.products) {
      if (!product.isActive || product.category != ProductCategory.bottle) {
        continue;
      }
      final icon = productIconByKey(product.iconKey).icon;
      for (final variant in product.variants) {
        final existing = _find(product.id, variant.id);
        list.add(
          _CustomerSelectableItem(
            productId: product.id,
            variantId: variant.id,
            title: product.name,
            subtitle: variant.label,
            icon: icon,
            shopRate: variant.price,
            enabled: existing?.enabled ?? false,
            currentRate: existing?.unitPrice ?? variant.price,
          ),
        );
      }
    }
    return list;
  }

  void _toggleItem(_CustomerSelectableItem item) {
    final nowEnabled = !(item.enabled);
    _upsert(
      CustomerProductPrice(
        productId: item.productId,
        variantId: item.variantId,
        unitPrice: item.currentRate,
        enabled: nowEnabled,
      ),
    );
  }

  void _setItemPrice(_CustomerSelectableItem item, double value) {
    final existing = _find(item.productId, item.variantId);
    _upsert(
      CustomerProductPrice(
        productId: item.productId,
        variantId: item.variantId,
        unitPrice: value,
        enabled: existing?.enabled ?? item.enabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _allSelectableItems();
    final enabledItems = allItems.where((item) => item.enabled).toList();

    if (widget.embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UnifiedProductsCard(
            embedded: true,
            items: allItems,
            onToggle: _toggleItem,
          ),
          if (enabledItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            _EnabledItemsPricingCard(
              embedded: true,
              items: enabledItems,
              onDisable: (item) => _toggleItem(item),
              onPriceChanged: _setItemPrice,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products & pricing',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AddEditCustomerColors.labelGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set what this customer buys and their rates',
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
                  'Shop rates',
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UnifiedProductsCard(
                embedded: false,
                items: allItems,
                onToggle: _toggleItem,
              ),
              if (enabledItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                _EnabledItemsPricingCard(
                  embedded: false,
                  items: enabledItems,
                  onDisable: (item) => _toggleItem(item),
                  onPriceChanged: _setItemPrice,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _CustomerSelectableItem {
  const _CustomerSelectableItem({
    required this.productId,
    required this.variantId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.shopRate,
    required this.enabled,
    required this.currentRate,
  });

  final String productId;
  final String variantId;
  final String title;
  final String subtitle;
  final IconData icon;
  final double shopRate;
  final bool enabled;
  final double currentRate;
}

class _UnifiedProductsCard extends StatelessWidget {
  const _UnifiedProductsCard({
    required this.items,
    required this.onToggle,
    this.embedded = false,
  });

  final List<_CustomerSelectableItem> items;
  final ValueChanged<_CustomerSelectableItem> onToggle;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, i) => _SelectableProductBox(
        item: items[i],
        onTap: () => onToggle(items[i]),
      ),
    );

    if (embedded) return grid;

    return _PricingCardShell(
      embedded: false,
      icon: Icons.grid_view_rounded,
      iconColor: const Color(0xFF2563EB),
      title: 'Products',
      subtitle: 'Tap a card to enable/disable for this customer',
      child: grid,
    );
  }
}

class _SelectableProductBox extends StatelessWidget {
  const _SelectableProductBox({
    required this.item,
    required this.onTap,
  });

  final _CustomerSelectableItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.enabled ? const Color(0xFFF0F9FF) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.enabled
                  ? const Color(0xFF2563EB)
                  : AddEditCustomerColors.fieldBorder,
              width: item.enabled ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 22,
                color: item.enabled
                    ? const Color(0xFF2563EB)
                    : AddEditCustomerColors.labelGrey,
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: AddEditCustomerColors.labelGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnabledItemsPricingCard extends StatelessWidget {
  const _EnabledItemsPricingCard({
    required this.items,
    required this.onDisable,
    required this.onPriceChanged,
    this.embedded = false,
  });

  final List<_CustomerSelectableItem> items;
  final ValueChanged<_CustomerSelectableItem> onDisable;
  final void Function(_CustomerSelectableItem item, double value) onPriceChanged;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _VariantPriceRow(
            label: items[i].title,
            enabled: items[i].enabled,
            price: items[i].currentRate,
            shopHint: items[i].shopRate,
            onEnabled: (_) => onDisable(items[i]),
            onPrice: (v) => onPriceChanged(items[i], v),
          ),
          if (i != items.length - 1) SizedBox(height: embedded ? 6 : 10),
        ],
      ],
    );

    if (embedded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Customer prices',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AddEditCustomerColors.labelGrey,
            ),
          ),
          const SizedBox(height: 8),
          rows,
        ],
      );
    }

    return _PricingCardShell(
      embedded: false,
      icon: Icons.currency_rupee_rounded,
      iconColor: const Color(0xFF2563EB),
      title: 'Enabled products',
      subtitle: 'Set customer-specific price only for selected products',
      child: rows,
    );
  }
}

class _DeliveryTypesCustomerSection extends StatelessWidget {
  const _DeliveryTypesCustomerSection({
    required this.isEnabled,
    required this.priceFor,
    required this.shopRateFor,
    required this.onToggle,
    required this.onPrice,
    this.embedded = false,
  });

  final bool Function(DeliveryProductType type) isEnabled;
  final double Function(DeliveryProductType type) priceFor;
  final double Function(DeliveryProductType type) shopRateFor;
  final ValueChanged<DeliveryProductType> onToggle;
  final void Function(DeliveryProductType type, double price) onPrice;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final enabledTypes =
        DeliveryProductType.catalog.where(isEnabled).toList();

    return _PricingCardShell(
      embedded: embedded,
      icon: Icons.grid_view_rounded,
      iconColor: const Color(0xFF2563EB),
      title: 'Delivery product types',
      subtitle: 'Tap to enable or disable for this customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeliveryProductTypeGrid(
            compact: true,
            types: DeliveryProductType.catalog,
            builder: (context, type) {
              final enabled = isEnabled(type);
              return DeliveryProductTypeBox(
                type: type,
                compact: true,
                selected: enabled,
                enabled: enabled,
                onTap: () => onToggle(type),
              );
            },
          ),
          if (enabledTypes.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < enabledTypes.length; i++) ...[
              _VariantPriceRow(
                label: enabledTypes[i].title,
                enabled: true,
                price: priceFor(enabledTypes[i]),
                shopHint: shopRateFor(enabledTypes[i]),
                onEnabled: (_) => onToggle(enabledTypes[i]),
                onPrice: (v) => onPrice(enabledTypes[i], v),
              ),
              if (i != enabledTypes.length - 1) const SizedBox(height: 10),
            ],
          ],
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
      icon: productIconByKey(product.iconKey).icon,
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
      margin: EdgeInsets.only(bottom: embedded ? 0 : 12),
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
            padding: EdgeInsets.fromLTRB(14, 12, 14, embedded ? 10 : 14),
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
                  'Shop: ${CurrencyUtils.format(shopHint)}',
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
