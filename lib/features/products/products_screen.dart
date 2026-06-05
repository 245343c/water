import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/widgets/delivery_product_type_widgets.dart';

/// Shop delivery product types and default rates (fixed catalog).
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final catalogProducts = repo.products
            .where((p) => p.category == ProductCategory.bottle)
            .toList();

        void openAddProduct() => context.push('/products/add');

        Future<void> onEditCatalogProduct(product) async {
          final result = await showCatalogProductDialog(context, product: product);
          if (!context.mounted || result == null) return;
          if (result.delete) {
            await repo.deleteProduct(product.id);
            return;
          }
          if (result.updatedPrice != null) {
            await repo.updateProductStartingPrice(
              product.id,
              result.updatedPrice!,
            );
          }
        }

        Future<void> onEditRate(type, current) async {
          final rate = await showDeliveryTypeRateDialog(
            context,
            type: type,
            currentRate: current,
          );
          if (rate != null && context.mounted) {
            await repo.updateDeliveryTypeShopRate(type, rate);
          }
        }

        final listChildren = buildProductsListChildren(
          rateFor: repo.shopDefaultRateForDeliveryType,
          onEditRate: onEditRate,
          catalogProducts: catalogProducts,
          onEditCatalogProduct: onEditCatalogProduct,
          query: _search.text,
        );

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: CustomersScaffold(
            usePageGradient: true,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomersHeader(
                    title: 'Products',
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF34D399),
                    showAddButton: false,
                    onAdd: openAddProduct,
                    searchController: _search,
                    onSearchChanged: (_) => setState(() {}),
                    searchHint: 'Search products, rates...',
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                      children: listChildren,
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: ProductsAddProductButton(onPressed: openAddProduct),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}
