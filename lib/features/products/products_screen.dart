import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/data/models/product_category.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/products/widgets/delivery_product_type_widgets.dart';
import 'package:sri_sai_ro_water/features/products/widgets/products_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Shop delivery product types and default rates (fixed catalog).
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final catalogProducts = repo.products
            .where((p) => p.category == ProductCategory.bottle)
            .toList();

        return Scaffold(
          backgroundColor: CustomersColors.screenBg,
          body: ProductsScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomersHeader(
                  title: 'Products',
                  showAddButton: true,
                  onAdd: () => context.push('/products/add'),
                  onMenu: () => context.go(AppRoutes.more),
                ),
                CustomersListPanel(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      ProductsDeliveryTypesSection(
                        rateFor: repo.shopDefaultRateForDeliveryType,
                        catalogProducts: catalogProducts,
                        onEditCatalogProduct: (product) async {
                          final result = await showCatalogProductDialog(
                            context,
                            product: product,
                          );
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
                        },
                        onEditRate: (type, current) async {
                          final rate = await showDeliveryTypeRateDialog(
                            context,
                            type: type,
                            currentRate: current,
                          );
                          if (rate != null && context.mounted) {
                            await repo.updateDeliveryTypeShopRate(type, rate);
                          }
                        },
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
