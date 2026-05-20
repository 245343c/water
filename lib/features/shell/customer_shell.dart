import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Branches: 0=Home 1=Account(bulk) 2=Orders 3=Promotions 4=Profile
  ///
  /// Retail nav: Home·Orders·Promos·Profile → branches 0,2,3,4
  /// Bulk nav:   Home·Account·Orders·Promos·Profile → branches 0,1,2,3,4
  int _navToBranch(bool isContract, int navIndex) {
    if (isContract) return navIndex;
    return switch (navIndex) {
      0 => 0,
      1 => 2,
      2 => 3,
      3 => 4,
      _ => 0,
    };
  }

  int _branchToNav(bool isContract, int branchIndex) {
    if (isContract) return branchIndex;
    return switch (branchIndex) {
      0 => 0,
      2 => 1,
      3 => 2,
      4 => 3,
      _ => 0,
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

    final selectedNav = _branchToNav(isContract, navigationShell.currentIndex);

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
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
            indicatorColor: CustomerColors.accent.withValues(alpha: 0.12),
            selectedIndex: selectedNav,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? CustomerColors.accent : CustomerColors.labelGrey,
              );
            }),
            onDestinationSelected: (i) => navigationShell.goBranch(
              _navToBranch(isContract, i),
              initialLocation:
                  _navToBranch(isContract, i) == navigationShell.currentIndex,
            ),
            destinations: isContract
                ? [
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
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: pendingOrders > 0,
                        label: Text('$pendingOrders'),
                        child: const Icon(Icons.receipt_long_outlined),
                      ),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: 'Orders',
                    ),
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
                  ]
                : [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: pendingOrders > 0,
                        label: Text('$pendingOrders'),
                        child: const Icon(Icons.receipt_long_outlined),
                      ),
                      selectedIcon: const Icon(Icons.receipt_long),
                      label: 'Orders',
                    ),
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
                  ],
          ),
        ),
      ),
    );
  }
}
