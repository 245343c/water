import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        return Scaffold(
          backgroundColor: MoreColors.screenBg,
          body: MoreScaffold(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MoreHeader(title: 'Account'),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 24),
                      children: [
                        MoreBusinessProfileCard(
                          settings: repo.settings,
                          onTap: () => context.push('/settings'),
                        ),
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
