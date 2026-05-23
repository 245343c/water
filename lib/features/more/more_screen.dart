import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/notification_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/shop_location_card.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WaterPlantRepository repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reset mock data?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('All test changes will be lost.', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      repo.resetMockData();
      context.read<NotificationRepository>().clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock data restored'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        final monthDeliveries = repo.deliveriesInRange(monthStart, monthEnd);
        final monthSales = monthDeliveries.fold<double>(0, (s, d) => s + d.totalAmount);
        final monthCans = monthDeliveries.fold<int>(0, (s, d) => s + d.normalQty + d.coolQty);
        final monthCollected = repo.paymentsTotalInRange(monthStart, monthEnd);

        return Scaffold(
          backgroundColor: MoreColors.screenBg,
          body: MoreScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MoreHeader(
                  title: 'Menu',
                  subtitle: 'Shop settings · team · reports',
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
                        child: Text(
                          'INSIGHTS',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: MoreColors.labelGrey,
                          ),
                        ),
                      ),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
                        child: Text(
                          'TEAM',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: MoreColors.labelGrey,
                          ),
                        ),
                      ),
                      MoreMenuTile(
                        icon: Icons.local_shipping_rounded,
                        title: 'Drivers',
                        subtitle: 'Delivery staff logins',
                        onTap: () => context.push(AppRoutes.drivers),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
                        child: Text(
                          'ACCOUNT',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: MoreColors.labelGrey,
                          ),
                        ),
                      ),
                      MoreAccountCard(
                        onSignOut: () {
                          context.read<AuthRepository>().logout();
                          context.go(AppRoutes.welcome);
                        },
                        onResetMock: () => _confirmReset(context, repo),
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
