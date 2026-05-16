import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final pendingOrders = repo.pendingOrderCount;

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              height: 64,
              elevation: 0,
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primary.withValues(alpha: 0.1),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Dashboard',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: 'Customers',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: pendingOrders > 0,
                    label: Text('$pendingOrders'),
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: pendingOrders > 0,
                    label: Text('$pendingOrders'),
                    child: const Icon(Icons.receipt_long),
                  ),
                  label: 'Orders',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping),
                  label: 'Deliveries',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.menu_outlined),
                  selectedIcon: Icon(Icons.menu),
                  label: 'Menu',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
