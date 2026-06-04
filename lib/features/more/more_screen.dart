import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/business_setup_form.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';
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
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MoreHeader(
                    title: 'More',
                    subtitle: 'Business, insights and account',
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 24),
                      children: [
                        AddEditCustomerSectionCard(
                          title: 'Your business',
                          subtitle:
                              'Profile, shop location and customer app',
                          child: const BusinessSetupForm(),
                        ),
                        const MoreSectionTitle(title: 'Insights'),
                        MoreInsightsReportCard(
                          monthSales: monthSales,
                          monthCans: monthCans,
                          monthCollected: monthCollected,
                          onTap: () => context.push(AppRoutes.reports),
                        ),
                        const MoreSectionTitle(title: 'Management'),
                        MoreManagementCard(
                          onDrivers: () => context.push(AppRoutes.drivers),
                          onSignOut: () {
                            context.read<AuthRepository>().logout();
                            context.go(AppRoutes.welcome);
                          },
                        ),
                        const MoreVersionLabel(),
                      ],
                    ),
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
