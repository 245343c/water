import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_account_banner.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_shop_widgets.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

/// Home for all customers: search + shops. Contract users also see account banner.
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final userId = user?.id;
    final isContract = userId != null &&
        repo.isMonthlyContractAppUser(userId, phone: user?.phone);
    final crm = userId != null ? repo.linkedCrmCustomerForAppUser(userId) : null;
    final firstName = (crm?.name ?? user?.ownerName ?? 'Guest').split(' ').first;
    final shops = repo.searchListedShops(_query);
    final profile = userId != null ? repo.customerProfileByUserId(userId) : null;
    final pendingOrders = userId != null
        ? repo.ordersForAppUser(userId).where((o) => o.isPending).length
        : 0;

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomerHeader(
              title: 'Hello, $firstName',
              subtitle: isContract
                  ? 'Order from any shop · Track your monthly account'
                  : 'Search shops and order RO water cans',
            ),
            Expanded(
              child: ListView(
                children: [
                  CustomerHeroStats(
                    leftLabel: 'Shops',
                    leftValue: '${repo.listedShops().length}',
                    centerLabel: isContract ? 'Pending' : 'Orders',
                    centerValue: isContract && crm != null
                        ? CurrencyUtils.format(
                            repo.customerBalance(crm.id).clamp(0, double.infinity),
                          )
                        : '$pendingOrders',
                    rightLabel: 'Delivery',
                    rightValue: 'ON',
                  ),
                  if (isContract && crm != null)
                    CustomerAccountBanner(crm: crm, repo: repo),
                  if (!isContract && profile != null)
                    CustomerDeliveryChip(
                      address: profile.address,
                      onEdit: () => context.push(AppRoutes.customerOnboarding),
                    ),
                  CustomerSearchBar(
                    controller: _searchController,
                    onChanged: (q) => setState(() => _query = q),
                  ),
                  CustomerSectionTitle(
                    title: _query.isEmpty
                        ? 'Find a shop (${shops.length})'
                        : 'Search results (${shops.length})',
                  ),
                  if (shops.isEmpty)
                    const CustomerEmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'No shops found',
                      message:
                          'Try another search or check back later for new water plants.',
                    )
                  else
                    ...shops.map(
                      (shop) => CustomerShopCard(
                        shop: shop,
                        onTap: () => context.push('/customer/shop/${shop.id}'),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
