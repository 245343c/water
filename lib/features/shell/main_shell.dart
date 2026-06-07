import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
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
        final isDashboard = navigationShell.currentIndex == 0;
        final strings = context.l10n;

        return PopScope(
          canPop: isDashboard,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (!isDashboard) {
              navigationShell.goBranch(0);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: _ResponsiveShellBody(child: navigationShell),
            bottomNavigationBar: _ResponsiveBottomNav(
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
                  NavigationDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home),
                    label: strings.dashboard,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.people_outline),
                    selectedIcon: const Icon(Icons.people),
                    label: strings.customers,
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
                    label: strings.quickOrder,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.inventory_2_outlined),
                    selectedIcon: const Icon(Icons.inventory_2),
                    label: strings.products,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.account_circle_outlined),
                    selectedIcon: const Icon(Icons.account_circle),
                    label: strings.account,
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

class _ResponsiveShellBody extends StatelessWidget {
  const _ResponsiveShellBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 1180.0);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}

class _ResponsiveBottomNav extends StatelessWidget {
  const _ResponsiveBottomNav({required this.child, required this.decoration});

  final Widget child;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 1180.0);
          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: SizedBox(
              width: width,
              child: DecoratedBox(decoration: decoration, child: child),
            ),
          );
        },
      ),
    );
  }
}
