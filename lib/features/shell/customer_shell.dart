import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/customer_contract_account_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_home_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_orders_screen.dart';
import 'package:sri_sai_ro_water/features/customer/customer_profile_screen.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

abstract final class _CustomerRoutes {
  static const home = '/customer/home';
  static const account = '/customer/account';
  static const orders = '/customer/orders';
  static const profile = '/customer/profile';
}

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.location});

  final Uri location;

  String get _path => location.path;

  int _navIndexForLocation(bool isContract) {
    if (_path.startsWith(_CustomerRoutes.account)) {
      return 0;
    }
    if (_path.startsWith(_CustomerRoutes.orders)) {
      return 1;
    }
    if (_path.startsWith(_CustomerRoutes.profile)) {
      return 2;
    }
    return 0;
  }

  String _routeForNav(bool isContract, int navIndex) {
    if (isContract) {
      return switch (navIndex) {
        0 => _CustomerRoutes.home,
        1 => _CustomerRoutes.orders,
        2 => _CustomerRoutes.profile,
        _ => _CustomerRoutes.home,
      };
    }

    return switch (navIndex) {
      0 => _CustomerRoutes.home,
      1 => _CustomerRoutes.orders,
      2 => _CustomerRoutes.profile,
      _ => _CustomerRoutes.home,
    };
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final repo = context.watch<WaterPlantRepository>();
    final user = auth.currentUser;
    final userId = user?.id;
    final isContract =
        userId != null &&
        repo.isMonthlyContractAppUser(userId, phone: user?.phone);
    final pendingOrders = userId != null
        ? repo.ordersForAppUser(userId).where((o) => o.isPending).length
        : 0;

    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = _customerShellMaxWidth(context);
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: math.min(constraints.maxWidth, maxWidth),
              height: constraints.maxHeight,
              child: _tabForLocation(isContract: isContract),
            ),
          );
        },
      ),
      bottomNavigationBar: _CustomerBottomNavigation(
        isContract: isContract,
        selectedIndex: _navIndexForLocation(isContract),
        pendingOrders: pendingOrders,
        onDestinationSelected: (i) => context.go(_routeForNav(isContract, i)),
      ),
    );
  }

  Widget _tabForLocation({required bool isContract}) {
    try {
      if (_path.startsWith(_CustomerRoutes.account)) {
        return CustomerContractAccountScreen(
          focusShopId: location.queryParameters['shopId'],
        );
      }
      if (_path.startsWith(_CustomerRoutes.orders)) {
        return const CustomerOrdersScreen();
      }
      if (_path.startsWith(_CustomerRoutes.profile)) {
        return const CustomerProfileScreen();
      }
      return const CustomerHomeScreen();
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: CustomerColors.labelGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load this page',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CustomerColors.titleNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: CustomerColors.labelGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
          final maxWidth = _customerShellMaxWidth(context);
          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: SizedBox(
              width: math.min(constraints.maxWidth, maxWidth),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: CustomerColors.cardBorder),
                    ),
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
                    indicatorColor: CustomerColors.accent.withValues(
                      alpha: 0.12,
                    ),
                    selectedIndex: selectedIndex,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final selected = states.contains(WidgetState.selected);
                      return GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
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
      _ordersDestination(),
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

double _customerShellMaxWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1100) return 1180;
  if (width >= 700) return 1180;
  return width;
}
