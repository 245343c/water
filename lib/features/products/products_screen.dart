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
      _ProductFilter.bottles =>
        list.where((p) => p.category == ProductCategory.bottle).toList(),
      _ProductFilter.cans =>
        list.where((p) => p.category == ProductCategory.can).toList(),
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
                  hintText: 'Search products…',
                  onChanged: (v) => setState(() => _query = v),
                ),
                CustomersListPanel(
                  child: Column(
                    children: [
                      const _ProductPricingNote(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
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
                            ? _EmptyProducts(
                                isSearch: _query.isNotEmpty || _filter != _ProductFilter.all,
                                onAdd: () => context.push('/products/add'),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, i) {
                                  final p = products[i];
                                  return ProductCatalogCard(
                                    product: p,
                                    onTap: () => context.push('/products/${p.id}'),
                                  );
                                },
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
        child: Text(
          'No products found',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: ProductsColors.labelGrey,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: ProductsColors.statBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your catalog is empty',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ProductsColors.titleNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add bottles and water cans here. Final rates are assigned inside each customer profile.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: ProductsColors.labelGrey,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
              style: FilledButton.styleFrom(
                backgroundColor: CustomersColors.addButton,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPricingNote extends StatelessWidget {
  const _ProductPricingNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sell_outlined,
            color: ProductsColors.statBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Products are your catalog. Customer-specific rates are assigned when admin creates or edits a customer.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                height: 1.35,
                color: ProductsColors.titleNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
