import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/shop_map_launcher.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/models/product_variant.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerShopScreen extends StatefulWidget {
  const CustomerShopScreen({super.key, required this.shopId});

  final String shopId;

  @override
  State<CustomerShopScreen> createState() => _CustomerShopScreenState();
}

class _CustomerShopScreenState extends State<CustomerShopScreen> {
  int _normal = 0;
  int _cool = 0;
  final _noteController = TextEditingController();
  final Map<String, int> _variantQty = {};
  bool _placing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _variantKey(String productId, String variantId) => '$productId:$variantId';

  int _qtyFor(Product product, ProductVariant variant) =>
      _variantQty[_variantKey(product.id, variant.id)] ?? 0;

  void _setVariantQty(Product product, ProductVariant variant, int qty) {
    setState(() {
      if (qty <= 0) {
        _variantQty.remove(_variantKey(product.id, variant.id));
      } else {
        _variantQty[_variantKey(product.id, variant.id)] = qty;
      }
    });
  }

  int _catalogNormalQty(List<Product> products) {
    var n = 0;
    for (final p in products) {
      if (p.category != ProductCategory.can) continue;
      for (final v in p.variants) {
        if (!v.isCool) n += _qtyFor(p, v);
      }
    }
    return n;
  }

  int _catalogCoolQty(List<Product> products) {
    var n = 0;
    for (final p in products) {
      if (p.category != ProductCategory.can) continue;
      for (final v in p.variants) {
        if (v.isCool) n += _qtyFor(p, v);
      }
    }
    return n;
  }

  double _catalogBottlesTotal(List<Product> products) {
    var total = 0.0;
    for (final p in products) {
      if (p.category != ProductCategory.bottle) continue;
      for (final v in p.variants) {
        total += _qtyFor(p, v) * v.price;
      }
    }
    return total;
  }

  String? _buildProductSummary(List<Product> products) {
    final lines = <String>[];
    for (final p in products) {
      for (final v in p.variants) {
        final q = _qtyFor(p, v);
        if (q > 0) {
          lines.add('$q × ${p.name} (${v.label})');
        }
      }
    }
    if (lines.isEmpty) return null;
    return 'Products: ${lines.join(' · ')}';
  }

  double _orderTotal(Shop shop, List<Product> products) {
    final cans = _normal * shop.normalPrice +
        _cool * shop.coolPrice +
        _catalogNormalQty(products) * shop.normalPrice +
        _catalogCoolQty(products) * shop.coolPrice;
    return cans + _catalogBottlesTotal(products);
  }

  int _totalItems(List<Product> products) {
    final catalog = _variantQty.values.fold<int>(0, (s, q) => s + q);
    return _normal + _cool + catalog;
  }

  Future<void> _placeOrder(
    WaterPlantRepository repo,
    AuthRepository auth,
    Shop shop,
    List<Product> products,
  ) async {
    final user = auth.currentUser;
    if (user == null) return;
    if (_totalItems(products) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one item'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final normalTotal = _normal + _catalogNormalQty(products);
      final coolTotal = _cool + _catalogCoolQty(products);
      repo.placeAppOrder(
        shopId: widget.shopId,
        appUserId: user.id,
        normalQty: normalTotal,
        coolQty: coolTotal,
        customerNote: _noteController.text,
        productSummary: _buildProductSummary(products),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed! Shop will confirm shortly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/customer/orders');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<WaterPlantRepository>();
    final auth = context.watch<AuthRepository>();
    final shop = repo.shopById(widget.shopId);
    final products = repo.catalogProducts();

    if (shop == null || !shop.isVisibleToCustomers) {
      return Scaffold(
        backgroundColor: CustomerColors.screenBg,
        body: CustomerScaffold(
          child: Column(
            children: [
              CustomerHeader(
                title: 'Shop',
                onBack: () => context.go(AppRoutes.customerHome),
              ),
              const Expanded(
                child: CustomerEmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Shop not available',
                  message: 'This shop does not offer home delivery on the app.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = _orderTotal(shop, products);
    final itemCount = _totalItems(products);

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 220,
                    pinned: true,
                    backgroundColor: CustomerColors.headerStart,
                    foregroundColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 48, bottom: 14, right: 16),
                      title: Text(
                        shop.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      background: _ShopHeroBackground(shop: shop),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ShopDetailsCard(shop: shop),
                          const SizedBox(height: 20),
                          CustomerSectionTitle(title: '20L water cans'),
                          const SizedBox(height: 10),
                          _CanQtyCard(
                            label: 'Normal RO',
                            price: shop.normalPrice,
                            qty: _normal,
                            icon: Icons.water_drop_outlined,
                            color: CustomerColors.accent,
                            onChanged: (v) => setState(() => _normal = v),
                          ),
                          const SizedBox(height: 10),
                          _CanQtyCard(
                            label: 'Cool RO',
                            price: shop.coolPrice,
                            qty: _cool,
                            icon: Icons.ac_unit_rounded,
                            color: const Color(0xFF0EA5E9),
                            onChanged: (v) => setState(() => _cool = v),
                          ),
                          if (products.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            CustomerSectionTitle(
                              title: 'Products (${products.length})',
                            ),
                            const SizedBox(height: 10),
                            ...products.expand(
                              (p) => p.variants.map(
                                (v) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ProductOrderCard(
                                    product: p,
                                    variant: v,
                                    qty: _qtyFor(p, v),
                                    onChanged: (q) => _setVariantQty(p, v, q),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          CustomerTextField(
                            label: 'Note to shop (optional)',
                            controller: _noteController,
                            hint: 'Delivery instructions',
                            icon: Icons.note_alt_outlined,
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _OrderBottomBar(
              itemCount: itemCount,
              total: total,
              loading: _placing,
              onPlace: () => _placeOrder(repo, auth, shop, products),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopDetailsCard extends StatelessWidget {
  const _ShopDetailsCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: CustomerColors.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CustomerColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: CustomerColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.titleNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '4.8 · Home delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: CustomerColors.labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.location_on_outlined, label: 'Address', value: shop.address),
          if (shop.place.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.place_outlined, label: 'Area', value: shop.place),
          ],
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: shop.phone,
            onTap: () => Clipboard.setData(ClipboardData(text: shop.phone)),
          ),
          if (shop.email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(icon: Icons.mail_outline_rounded, label: 'Email', value: shop.email),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _PriceChip(
                label: 'Normal',
                price: CurrencyUtils.format(shop.normalPrice),
              ),
              const SizedBox(width: 8),
              _PriceChip(
                label: 'Cool',
                price: CurrencyUtils.format(shop.coolPrice),
                cool: true,
              ),
            ],
          ),
          if (shop.hasMapPin) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ShopMapLauncher.directions(
                  address: shop.address,
                  latitude: shop.latitude,
                  longitude: shop.longitude,
                ),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: Text(
                  'Get directions',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CustomerColors.accent,
                  side: const BorderSide(color: CustomerColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CustomerColors.labelGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CustomerColors.labelGrey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CustomerColors.titleNavy,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.copy_rounded, size: 16, color: CustomerColors.accent),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.price, this.cool = false});

  final String label;
  final String price;
  final bool cool;

  @override
  Widget build(BuildContext context) {
    final color = cool ? const Color(0xFF0EA5E9) : CustomerColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label $price',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CanQtyCard extends StatelessWidget {
  const _CanQtyCard({
    required this.label,
    required this.price,
    required this.qty,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double price;
  final int qty;
  final IconData icon;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: CustomerColors.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CustomerColors.titleNavy,
                  ),
                ),
                Text(
                  '${CurrencyUtils.format(price)} each',
                  style: GoogleFonts.poppins(fontSize: 12, color: CustomerColors.labelGrey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: qty > 0 ? () => onChanged(qty - 1) : null,
            icon: Icon(Icons.remove_circle_outline_rounded, color: color),
          ),
          Text(
            '$qty',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: () => onChanged(qty + 1),
            icon: Icon(Icons.add_circle_rounded, color: color),
          ),
        ],
      ),
    );
  }
}

class _ProductOrderCard extends StatelessWidget {
  const _ProductOrderCard({
    required this.product,
    required this.variant,
    required this.qty,
    required this.onChanged,
  });

  final Product product;
  final ProductVariant variant;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isBottle = product.category == ProductCategory.bottle;
    final accent = variant.isCool
        ? const Color(0xFF0EA5E9)
        : (isBottle ? CustomerColors.accent : CustomerColors.success);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: CustomerColors.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CustomerColors.titleNavy,
                  ),
                ),
                Text(
                  variant.label,
                  style: GoogleFonts.poppins(fontSize: 12, color: CustomerColors.labelGrey),
                ),
                Text(
                  CurrencyUtils.format(variant.price),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: qty > 0 ? () => onChanged(qty - 1) : null,
            icon: Icon(Icons.remove_circle_outline_rounded, color: accent),
          ),
          Text('$qty', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          IconButton(
            onPressed: () => onChanged(qty + 1),
            icon: Icon(Icons.add_circle_rounded, color: accent),
          ),
        ],
      ),
    );
  }
}

/// Shop hero: illustrated background with shop name letter + tagline.
/// Shows shop image if coverImageUrl is set, otherwise premium illustrated card.
class _ShopHeroBackground extends StatelessWidget {
  const _ShopHeroBackground({required this.shop});

  final Shop shop;

  // Gradient palette derived from shop ID
  static const _palettes = [
    [Color(0xFF0F172A), Color(0xFF1E3A8A)],
    [Color(0xFF134E4A), Color(0xFF0D9488)],
    [Color(0xFF4C1D95), Color(0xFF7C3AED)],
    [Color(0xFF7C2D12), Color(0xFFEA580C)],
    [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  ];

  List<Color> _palette() {
    final idx = shop.id.codeUnits.fold(0, (s, c) => s + c) % _palettes.length;
    return _palettes[idx];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _palette();
    final letter = shop.name.isNotEmpty ? shop.name[0].toUpperCase() : '?';

    if (shop.coverImageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(shop.coverImageUrl!, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: CustomPaint(painter: _ShopHeroPainter()),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (shop.tagline.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    shop.tagline,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              if (shop.rating > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (shop.reviewCount > 0)
                      Text(
                        ' (${shop.reviewCount})',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        // Gradient overlay for title legibility
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var i = 0; i < 3; i++) {
      final r = size.width * (0.18 + i * 0.14);
      canvas.drawCircle(Offset(size.width * 0.92, size.height * (0.1 + i * 0.3)), r, paint);
    }
    // Bottom wave
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, size.height * 0.65);
    for (var x = 0.0; x <= size.width; x += 3) {
      final y = size.height * 0.65 + math.sin((x / size.width) * math.pi * 4) * 12;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _OrderBottomBar extends StatelessWidget {
  const _OrderBottomBar({
    required this.itemCount,
    required this.total,
    required this.loading,
    required this.onPlace,
  });

  final int itemCount;
  final double total;
  final bool loading;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: CustomerColors.labelGrey,
                  ),
                ),
                Text(
                  CurrencyUtils.format(total),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CustomerColors.accent,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: CustomerPrimaryButton(
              label: 'Place order',
              loading: loading,
              icon: Icons.shopping_bag_outlined,
              onPressed: onPlace,
            ),
          ),
        ],
      ),
    );
  }
}
