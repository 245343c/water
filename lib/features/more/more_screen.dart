import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/shop_location_card.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        final monthDeliveries = repo.deliveriesInRange(monthStart, monthEnd);
        final monthSales = monthDeliveries.fold<double>(
          0,
          (s, d) => s + d.totalAmount,
        );
        final monthCans = monthDeliveries.fold<int>(
          0,
          (s, d) => s + d.normalQty + d.coolQty,
        );
        final monthCollected = repo.paymentsTotalInRange(monthStart, monthEnd);

        return Scaffold(
          backgroundColor: MoreColors.screenBg,
          body: MoreScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MoreHeader(
                  title: 'More',
                  subtitle: 'Business profile, team and account',
                ),
                Expanded(
                  child: ListView(
                    children: [
                      MoreBusinessProfileCard(
                        settings: repo.settings,
                        onTap: () => context.push('/settings'),
                      ),
                      ShopLocationCard(
                        settings: repo.settings,
                        onEditLocation: () => context.push('/settings'),
                      ),
                      MoreHomeDeliveryCard(
                        value: repo.settings.homeDeliveryAvailable,
                        onChanged: (v) {
                          repo.updateSettings(
                            repo.settings.copyWith(homeDeliveryAvailable: v),
                          );
                        },
                      ),
                      const MoreSectionTitle(title: 'Insights'),
                      MoreInsightsReportCard(
                        monthSales: monthSales,
                        monthCans: monthCans,
                        monthCollected: monthCollected,
                        onTap: () => context.push(AppRoutes.reports),
                      ),
                      MoreMenuTile(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Subscription',
                        subtitle: 'Admin plan, trial, renewal',
                        onTap: () => context.push(AppRoutes.subscription),
                      ),
                      const MoreSectionTitle(title: 'Team'),
                      MoreMenuTile(
                        icon: Icons.local_shipping_rounded,
                        title: 'Drivers',
                        subtitle: 'Delivery staff logins',
                        onTap: () => context.push(AppRoutes.drivers),
                      ),
                      const MoreSectionTitle(title: 'Account'),
                      MoreAccountCard(
                        onSignOut: () {
                          context.read<AuthRepository>().logout();
                          context.go(AppRoutes.welcome);
                        },
                      ),
                      const MoreVersionLabel(),
                      const SizedBox(height: 16),
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
