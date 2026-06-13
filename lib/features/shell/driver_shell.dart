import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Consumer3<
      WaterPlantRepository,
      NotificationRepository,
      AuthRepository
    >(
      builder: (context, repo, notifications, auth, _) {
        final driverId = auth.currentUser?.driverId;
        final tasks = repo.driverAcceptedOrders(driverId: driverId).length;
        final alerts = notifications.unreadCountForDriver(driverId: driverId);
        final badgeCount = tasks + alerts;
        final isCustomers = navigationShell.currentIndex == 0;
        final strings = context.l10n;

        return PopScope(
          canPop: isCustomers,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (!isCustomers) {
              navigationShell.goBranch(0);
            }
          },
          child: Scaffold(
            backgroundColor: DriverColors.screenBg,
            body: _ResponsiveDriverShellBody(child: navigationShell),
            bottomNavigationBar: _DriverBottomNavFrame(
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
                indicatorColor: DriverColors.accent.withValues(alpha: 0.12),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? DriverColors.accent
                        : DriverColors.labelGrey,
                  );
                }),
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (i) => navigationShell.goBranch(
                  i,
                  initialLocation: i == navigationShell.currentIndex,
                ),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.people_outline),
                    selectedIcon: const Icon(Icons.people_rounded),
                    label: strings.customers,
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: badgeCount > 0,
                      label: Text('$badgeCount'),
                      child: const Icon(Icons.route_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: badgeCount > 0,
                      label: Text('$badgeCount'),
                      child: const Icon(Icons.route_rounded),
                    ),
                    label: strings.deliveries,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: strings.profile,
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

class _ResponsiveDriverShellBody extends StatelessWidget {
  const _ResponsiveDriverShellBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        );
      },
    );
  }
}

class _DriverBottomNavFrame extends StatelessWidget {
  const _DriverBottomNavFrame({required this.child, required this.decoration});

  final Widget child;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return DecoratedBox(
            decoration: decoration,
            child: SizedBox(
              width: constraints.maxWidth,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
