import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/language_controller.dart';
import 'package:sri_sai_ro_water/core/localization/language_picker.dart';
import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
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
                  MoreHeader(title: context.l10n.account),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 14, 8, 24),
                      children: [
                        MoreBusinessProfileCard(
                          settings: repo.settings,
                          onTap: () => context.push('/settings'),
                        ),
                        const _AdminLanguageCard(),
                        MoreManagementCard(
                          onDrivers: () => context.push(AppRoutes.drivers),
                          onSignOut: () async {
                            await context
                                .read<PushNotificationService>()
                                .unregisterCurrentToken();
                            if (!context.mounted) return;
                            context.read<AuthRepository>().logout();
                            context.go(AppRoutes.login);
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

class _AdminLanguageCard extends StatelessWidget {
  const _AdminLanguageCard();

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final language = context.watch<LanguageController>().language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => showLanguagePicker(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.language_rounded, color: Color(0xFF1A73E8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.languageLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        language.nativeName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
