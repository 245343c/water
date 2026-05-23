import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/models/customer_order.dart';
import 'package:sri_sai_ro_water/data/models/promotion.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

abstract final class _CustomerRoutes {
  static const welcome = '/welcome';
  static const home = '/customer/home';
  static const account = '/customer/account';
  static const orders = '/customer/orders';
  static const promotions = '/customer/promotions';
  static const profile = '/customer/profile';
}

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.location});

  final String location;

  int _navIndexForLocation(bool isContract) {
    if (location.startsWith(_CustomerRoutes.account)) {
      return isContract ? 1 : 0;
    }
    if (location.startsWith(_CustomerRoutes.orders)) {
      return isContract ? 2 : 1;
    }
    if (location.startsWith(_CustomerRoutes.promotions)) {
      return isContract ? 3 : 2;
    }
    if (location.startsWith(_CustomerRoutes.profile)) {
      return isContract ? 4 : 3;
    }
    return 0;
  }

  String _routeForNav(bool isContract, int navIndex) {
    if (isContract) {
      return switch (navIndex) {
        0 => _CustomerRoutes.home,
        1 => _CustomerRoutes.account,
        2 => _CustomerRoutes.orders,
        3 => _CustomerRoutes.promotions,
        4 => _CustomerRoutes.profile,
        _ => _CustomerRoutes.home,
      };
    }

    return switch (navIndex) {
      0 => _CustomerRoutes.home,
      1 => _CustomerRoutes.orders,
      2 => _CustomerRoutes.promotions,
      3 => _CustomerRoutes.profile,
      _ => _CustomerRoutes.home,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final userId = user?.id;
    final isContract = userId != null &&
        repo.isMonthlyContractAppUser(userId, phone: user?.phone);
    final pendingOrders = userId != null
        ? repo.ordersForAppUser(userId).where((o) => o.isPending).length
        : 0;

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: SafeArea(
        top: false,
        child: _CustomerBody(location: location),
      ),
      bottomNavigationBar: _CustomerBottomNavigation(
        isContract: isContract,
        selectedIndex: _navIndexForLocation(isContract),
        pendingOrders: pendingOrders,
        onDestinationSelected: (i) => context.go(_routeForNav(isContract, i)),
      ),
    );
  }
}

class _CustomerBody extends StatelessWidget {
  const _CustomerBody({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    try {
      final auth = context.watch<AuthRepository>();
      final repo = context.watch<WaterPlantRepository>();
      final user = auth.currentUser;
      final userId = user?.id;
      final linkedShops = userId == null
          ? <Shop>[]
          : repo.linkedShopsForAppUser(userId, phone: user?.phone);

      if (location.startsWith(_CustomerRoutes.account)) {
        return _AccountTab(userId: userId, repo: repo);
      }
      if (location.startsWith(_CustomerRoutes.orders)) {
        return _OrdersTab(userId: userId, repo: repo);
      }
      if (location.startsWith(_CustomerRoutes.promotions)) {
        return _OffersTab(linkedShops: linkedShops, repo: repo);
      }
      if (location.startsWith(_CustomerRoutes.profile)) {
        return _ProfileTab(auth: auth, repo: repo);
      }
      return _HomeTab(auth: auth, repo: repo, linkedShops: linkedShops);
    } catch (error) {
      return _TabFrame(
        title: 'Customer app',
        subtitle: 'Could not load customer details',
        icon: Icons.error_outline_rounded,
        children: [
          _EmptyCard(
            icon: Icons.error_outline_rounded,
            title: 'Customer page error',
            message: error.toString(),
          ),
        ],
      );
    }
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.auth,
    required this.repo,
    required this.linkedShops,
  });

  final AuthRepository auth;
  final WaterPlantRepository repo;
  final List<Shop> linkedShops;

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final crm = user == null ? null : repo.linkedCrmCustomerForAppUser(user.id);
    final name = (crm?.name ?? user?.ownerName ?? 'Customer')
        .trim()
        .split(RegExp(r'\s+'))
        .first;

    return _TabFrame(
      title: 'Hello, $name',
      subtitle: linkedShops.isEmpty
          ? 'No water plant linked yet'
          : 'Order only from your linked water plant',
      icon: Icons.water_drop_rounded,
      children: [
        _InfoCard(
          icon: Icons.verified_user_rounded,
          title: crm?.name ?? user?.ownerName ?? 'Customer account',
          subtitle: linkedShops.isEmpty
              ? 'Ask your RO plant owner to add this mobile number.'
              : '${linkedShops.length} linked water plant${linkedShops.length == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 16),
        _SectionLabel(
          linkedShops.length == 1 ? 'YOUR WATER PLANT' : 'LINKED WATER PLANTS',
        ),
        const SizedBox(height: 8),
        if (linkedShops.isEmpty)
          const _EmptyCard(
            icon: Icons.storefront_rounded,
            title: 'No water plant linked yet',
            message:
                'Only admin-added customers can use this customer app. Please contact your RO plant owner.',
          )
        else
          ...linkedShops.map((shop) => _ShopCard(shop: shop)),
      ],
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.userId, required this.repo});

  final String? userId;
  final WaterPlantRepository repo;

  @override
  Widget build(BuildContext context) {
    final billings = userId == null ? [] : repo.shopBillingsForAppUser(userId!);
    final pending = userId == null ? 0.0 : repo.totalPendingForAppUser(userId!);

    return _TabFrame(
      title: 'Account',
      subtitle: 'Monthly billing from linked plants',
      icon: Icons.account_balance_wallet_rounded,
      children: [
        _InfoCard(
          icon: Icons.currency_rupee_rounded,
          title: 'Unpaid balance',
          subtitle: 'Rs ${pending.toStringAsFixed(0)} pending',
        ),
        const SizedBox(height: 16),
        const _SectionLabel('SHOP ACCOUNTS'),
        const SizedBox(height: 8),
        if (billings.isEmpty)
          const _EmptyCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No monthly account found',
            message: 'Your linked plant billing will appear here.',
          )
        else
          ...billings.map(
            (b) => _InfoCard(
              icon: Icons.storefront_rounded,
              title: b.shop.name,
              subtitle:
                  '${b.customer.name} - Rs ${repo.customerBalance(b.customer.id).toStringAsFixed(0)} pending',
            ),
          ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.userId, required this.repo});

  final String? userId;
  final WaterPlantRepository repo;

  @override
  Widget build(BuildContext context) {
    final orders = userId == null ? <CustomerOrder>[] : repo.ordersForAppUser(userId!);
    final pending = orders.where((o) => o.isPending).length;

    return _TabFrame(
      title: 'Orders',
      subtitle: orders.isEmpty ? 'Track water requests' : '$pending pending orders',
      icon: Icons.receipt_long_rounded,
      children: [
        if (orders.isEmpty)
          const _EmptyCard(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            message: 'Go to Home and open your linked water plant to place an order.',
          )
        else
          ...orders.map((order) => _OrderCard(order: order, repo: repo)),
      ],
    );
  }
}

class _OffersTab extends StatelessWidget {
  const _OffersTab({required this.linkedShops, required this.repo});

  final List<Shop> linkedShops;
  final WaterPlantRepository repo;

  @override
  Widget build(BuildContext context) {
    final linkedIds = linkedShops.map((s) => s.id).toSet();
    final offers = repo.promotions
        .where((p) => linkedIds.contains(p.shopId))
        .toList(growable: false);

    return _TabFrame(
      title: 'Offers',
      subtitle: 'Offers from your linked plants',
      icon: Icons.campaign_rounded,
      children: [
        if (offers.isEmpty)
          const _EmptyCard(
            icon: Icons.campaign_outlined,
            title: 'No offers right now',
            message: 'Your linked RO plant offers will appear here.',
          )
        else
          ...offers.map((offer) => _OfferCard(offer: offer)),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.auth, required this.repo});

  final AuthRepository auth;
  final WaterPlantRepository repo;

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    final crm = user == null ? null : repo.linkedCrmCustomerForAppUser(user.id);
    final name = crm?.name ?? user?.ownerName ?? 'Customer';
    final shopCount =
        user == null ? 0 : repo.linkedShopsForAppUser(user.id, phone: user.phone).length;

    return _TabFrame(
      title: 'Profile',
      subtitle: 'Customer app account',
      icon: Icons.person_rounded,
      children: [
        _InfoCard(
          icon: Icons.person_rounded,
          title: name,
          subtitle: user?.phone ?? 'No phone number',
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.storefront_rounded,
          title: 'Linked plants',
          subtitle: '$shopCount plant${shopCount == 1 ? '' : 's'} connected',
        ),
        const SizedBox(height: 20),
        CustomerPrimaryButton(
          label: 'Sign out',
          icon: Icons.logout_rounded,
          onPressed: () {
            auth.logout();
            context.go(_CustomerRoutes.welcome);
          },
        ),
      ],
    );
  }
}

class _TabFrame extends StatelessWidget {
  const _TabFrame({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _TabHeader(title: title, subtitle: subtitle, icon: icon),
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: CustomerColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: CustomerColors.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CustomerColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: CustomerColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CustomerColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: CustomerColors.labelGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: CustomerColors.labelGrey,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: CustomerColors.cardDecoration,
      child: Column(
        children: [
          Icon(icon, size: 42, color: CustomerColors.accent),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CustomerColors.titleNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: CustomerColors.labelGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/customer/shop/${shop.id}'),
      borderRadius: BorderRadius.circular(16),
      child: _InfoCard(
        icon: Icons.storefront_rounded,
        title: shop.name,
        subtitle: '${shop.address} - Tap to order water',
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.repo});

  final CustomerOrder order;
  final WaterPlantRepository repo;

  @override
  Widget build(BuildContext context) {
    final shopName =
        order.shopId == null ? 'Water order' : repo.shopById(order.shopId!)?.name;
    return _InfoCard(
      icon: Icons.receipt_long_rounded,
      title: shopName ?? 'Water order',
      subtitle:
          '${order.cansSummary} - ${order.status.label} - ${_formatDate(order.createdAt)}',
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final Promotion offer;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.campaign_rounded,
      title: offer.headline,
      subtitle: '${offer.shopName} - ${offer.body}',
    );
  }
}

class _CustomerBottomNavigation extends StatelessWidget {
  const _CustomerBottomNavigation({
    required this.isContract,
    required this.selectedIndex,
    required this.pendingOrders,
    required this.onDestinationSelected,
  });

  final bool isContract;
  final int selectedIndex;
  final int pendingOrders;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: math.min(constraints.maxWidth, 860),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: NavigationBar(
                  height: 64,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  indicatorColor:
                      CustomerColors.accent.withValues(alpha: 0.12),
                  selectedIndex: selectedIndex,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? CustomerColors.accent
                          : CustomerColors.labelGrey,
                    );
                  }),
                  onDestinationSelected: onDestinationSelected,
                  destinations: isContract
                      ? _contractDestinations()
                      : _retailDestinations(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<NavigationDestination> _retailDestinations() {
    return [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      _ordersDestination(),
      const NavigationDestination(
        icon: Icon(Icons.campaign_outlined),
        selectedIcon: Icon(Icons.campaign_rounded),
        label: 'Offers',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  List<NavigationDestination> _contractDestinations() {
    return [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet_rounded),
        label: 'Account',
      ),
      _ordersDestination(),
      const NavigationDestination(
        icon: Icon(Icons.campaign_outlined),
        selectedIcon: Icon(Icons.campaign_rounded),
        label: 'Offers',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  NavigationDestination _ordersDestination() {
    return NavigationDestination(
      icon: Badge(
        isLabelVisible: pendingOrders > 0,
        label: Text('$pendingOrders'),
        child: const Icon(Icons.receipt_long_outlined),
      ),
      selectedIcon: const Icon(Icons.receipt_long),
      label: 'Orders',
    );
  }
}
