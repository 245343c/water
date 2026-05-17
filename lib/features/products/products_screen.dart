import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/product.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/widgets/products_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

enum _ProductFilter { all, bottles, cans }

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  String _query = '';
  _ProductFilter _filter = _ProductFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> _filtered(WaterPlantRepository repo) {
    var list = repo.searchProducts(_query);
    return switch (_filter) {
      _ProductFilter.all => list,
      _ProductFilter.bottles => list.where((p) => p.category == ProductCategory.bottle).toList(),
      _ProductFilter.cans => list.where((p) => p.category == ProductCategory.can).toList(),
    };
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final products = _filtered(repo);

        return Scaffold(
          backgroundColor: CustomersColors.headerBottom,
          body: ProductsScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomersHeader(
                  title: 'Products',
                  onAdd: () => context.push('/products/add'),
                  onMenu: () => context.go(AppRoutes.more),
                ),
                CustomersSearchRow(
                  controller: _search,
                  hintText: 'Search products...',
                  onChanged: (v) => setState(() => _query = v),
                ),
                CustomersListPanel(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            ProductCategoryChip(
                              label: 'All',
                              selected: _filter == _ProductFilter.all,
                              onTap: () => setState(() => _filter = _ProductFilter.all),
                            ),
                            const SizedBox(width: 8),
                            ProductCategoryChip(
                              label: 'Bottles',
                              selected: _filter == _ProductFilter.bottles,
                              onTap: () => setState(() => _filter = _ProductFilter.bottles),
                            ),
                            const SizedBox(width: 8),
                            ProductCategoryChip(
                              label: 'Cans',
                              selected: _filter == _ProductFilter.cans,
                              onTap: () => setState(() => _filter = _ProductFilter.cans),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:                         products.isEmpty
                            ? _EmptyProducts(
                                isSearch: _query.isNotEmpty || _filter != _ProductFilter.all,
                                onAdd: () => context.push('/products/add'),
                              )
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    child: Text(
                                      '${products.length} product${products.length == 1 ? '' : 's'}',
                                      style: GoogleFonts.poppins(fontSize: 12, color: ProductsColors.labelGrey),
                                    ),
                                  ),
                                  for (final p in products)
                                    ProductSection(
                                      product: p,
                                      onTap: () => context.push('/products/${p.id}'),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.isSearch, this.onAdd});

  final bool isSearch;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (isSearch) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 52,
              color: ProductsColors.labelGrey.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            Text(
              'No products found',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ProductsColors.labelGrey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different search term',
              style: GoogleFonts.poppins(fontSize: 12, color: ProductsColors.labelGrey.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 44,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Products Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ProductsColors.titleNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your water bottles and cans to\nstart managing deliveries.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: ProductsColors.labelGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add First Product'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
