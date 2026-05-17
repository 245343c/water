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
                        child: products.isEmpty
                            ? _EmptyProducts(isSearch: _query.isNotEmpty || _filter != _ProductFilter.all)
                            : ListView(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                children: [
                                  Text(
                                    '${products.length} product${products.length == 1 ? '' : 's'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: ProductsColors.labelGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  for (final p in products)
                                    ProductListCard(
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
  const _EmptyProducts({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: ProductsColors.labelGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isSearch ? 'No products found' : 'No products yet',
            style: GoogleFonts.poppins(fontSize: 15, color: ProductsColors.labelGrey),
          ),
        ],
      ),
    );
  }
}
