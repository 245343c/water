import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmReset(BuildContext context, WaterPlantRepository repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset mock data?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'All test changes will be lost.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      repo.resetMockData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock data restored')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterPlantRepository>(
      builder: (context, repo, _) {
        return Scaffold(
          backgroundColor: MoreColors.screenBg,
          body: MoreScaffold(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MoreHeader(title: 'Menu'),
                Expanded(
                  child: ListView(
                    children: [
                      MoreBusinessProfileCard(
                        settings: repo.settings,
                        onTap: () => context.push('/settings'),
                      ),
                      MoreMenuTile(
                        icon: Icons.bar_chart_rounded,
                        title: 'Reports & Analytics',
                        subtitle: 'Cans, sales, charts',
                        onTap: () => context.push(AppRoutes.reports),
                      ),
                      MoreMenuTile(
                        icon: Icons.settings_outlined,
                        title: 'Business Settings',
                        subtitle: 'Name, email, address, can prices',
                        onTap: () => context.push('/settings'),
                      ),
                      const MoreSectionDivider(),
                      MoreMenuTile(
                        icon: Icons.logout_rounded,
                        title: 'Sign Out',
                        subtitle: 'Log out of your admin account',
                        showChevron: false,
                        onTap: () {
                          context.read<AuthRepository>().logout();
                          context.go(AppRoutes.login);
                        },
                      ),
                      const MoreSectionDivider(),
                      MoreMenuTile(
                        icon: Icons.refresh_rounded,
                        title: 'Reset Mock Data',
                        subtitle: 'Restore sample customers & deliveries',
                        showChevron: false,
                        onTap: () => _confirmReset(context, repo),
                      ),
                      const MoreVersionLabel(),
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
