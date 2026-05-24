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
        final totalProducts = repo.products.length;
        final bottleCount = repo.products
            .where((p) => p.category == ProductCategory.bottle)
            .length;
        final canCount = repo.products
            .where((p) => p.category == ProductCategory.can)
            .length;

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
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
                      _ProductsToolbar(
                        totalProducts: totalProducts,
                        bottleCount: bottleCount,
                        canCount: canCount,
                        selectedFilter: _filter,
                        onAdd: () => context.push('/products/add'),
                        onFilterChanged: (filter) =>
                            setState(() => _filter = filter),
                      ),
                      Expanded(
                        child: products.isEmpty
                            ? _EmptyProducts(
                                isSearch:
                                    _query.isNotEmpty ||
                                    _filter != _ProductFilter.all,
                                onAdd: () => context.push('/products/add'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  28,
                                ),
                                itemCount: products.length,
                                itemBuilder: (context, i) {
                                  final p = products[i];
                                  return ProductCatalogCard(
                                    product: p,
                                    onTap: () =>
                                        context.push('/products/${p.id}'),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 60
                  ? constraints.maxHeight - 60
                  : 0,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 54,
                    color: ProductsColors.statBlue.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your catalog is empty',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ProductsColors.titleNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add bottles and water cans here. Final rates are assigned inside each customer profile.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: ProductsColors.labelGrey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add product'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CustomersColors.addButton,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductsToolbar extends StatelessWidget {
  const _ProductsToolbar({
    required this.totalProducts,
    required this.bottleCount,
    required this.canCount,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onAdd,
  });

  final int totalProducts;
  final int bottleCount;
  final int canCount;
  final _ProductFilter selectedFilter;
  final ValueChanged<_ProductFilter> onFilterChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: ProductsColors.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ProductsColors.statBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: ProductsColors.statBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalProducts catalog products',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ProductsColors.titleNavy,
                      ),
                    ),
                    Text(
                      '$bottleCount bottles · $canCount cans',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: ProductsColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
                style: FilledButton.styleFrom(
                  backgroundColor: CustomersColors.addButton,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ProductCategoryChip(
                  label: 'All',
                  selected: selectedFilter == _ProductFilter.all,
                  onTap: () => onFilterChanged(_ProductFilter.all),
                ),
                const SizedBox(width: 8),
                ProductCategoryChip(
                  label: 'Bottles',
                  selected: selectedFilter == _ProductFilter.bottles,
                  onTap: () => onFilterChanged(_ProductFilter.bottles),
                ),
                const SizedBox(width: 8),
                ProductCategoryChip(
                  label: 'Cans',
                  selected: selectedFilter == _ProductFilter.cans,
                  onTap: () => onFilterChanged(_ProductFilter.cans),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: ProductsColors.labelGrey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Customer-specific rates are assigned in each customer profile.',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    height: 1.35,
                    color: ProductsColors.labelGrey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
