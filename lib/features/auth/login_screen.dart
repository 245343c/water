import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/localization/app_strings.dart';
import 'package:sri_sai_ro_water/core/localization/language_controller.dart';
import 'package:sri_sai_ro_water/core/localization/language_picker.dart';
import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
import 'package:sri_sai_ro_water/core/utils/input_validators.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/login_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';
import 'package:sri_sai_ro_water/routing/route_guard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();
    final push = context.read<PushNotificationService>();
    final strings = context.read<LanguageController>().strings;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final error = await auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null && auth.currentUser?.isDriver == true) {
      final driverId = auth.currentUser!.driverId;
      final driver = driverId != null
          ? await repo.loadDriverForCurrentUserFromFirestore(driverId)
          : null;
      if (driver == null || !driver.active) {
        if (!mounted) return;
        await push.unregisterCurrentToken();
        await auth.logout();
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(strings.inactiveDriver),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    router.go(homeRouteForRole(auth.currentUser!));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final strings = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginPremiumBackground(variant: LoginBackgroundVariant.auth),
          SafeArea(
            bottom: false,
            child: PremiumResponsiveBody(
              maxWidth: 480,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LoginCompactHero(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LoginAuthCard(
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          strings.signIn,
                                          style: GoogleFonts.poppins(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w800,
                                            color: LoginColors.brandNavy,
                                            letterSpacing: -0.5,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          strings.staffSubtitle,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: LoginColors.labelGrey,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const LoginRoleHintRow(),
                                        const SizedBox(height: 22),
                                        LoginTextField(
                                          label: strings.mobileNumber,
                                          controller: _emailController,
                                          hint: '98XXXXXXXX',
                                          icon: Icons.phone_iphone_rounded,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.next,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return strings.mobileRequired;
                                            }
                                            final text = v.trim();
                                            if (text.contains('@')) {
                                              return InputValidators.requiredEmail(
                                                text,
                                              );
                                            }
                                            if (!InputValidators.isValidIndianMobile(
                                              text,
                                            )) {
                                              return strings.validMobile;
                                            }
                                            return null;
                                          },
                                        ),
                                        Transform.translate(
                                          offset: const Offset(0, -8),
                                          child: Text(
                                            strings.driverLoginHint,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: LoginColors.labelGrey,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                        LoginTextField(
                                          label: strings.password,
                                          controller: _passwordController,
                                          hint: strings.yourPassword,
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted: (_) => _submit(),
                                          suffix: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: LoginColors.labelGrey,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscurePassword =
                                                  !_obscurePassword,
                                            ),
                                          ),
                                          validator: (v) =>
                                              v == null || v.isEmpty
                                              ? strings.passwordRequired
                                              : null,
                                        ),
                                        Transform.translate(
                                          offset: const Offset(0, -6),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton(
                                              onPressed: () => context.push(
                                                AppRoutes.forgotPassword,
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                strings.forgotPassword,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: LoginColors.primaryBtn,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        LoginSignInButton(
                                          loading: _loading,
                                          onPressed: _submit,
                                          embedded: true,
                                        ),
                                        const SizedBox(height: 16),
                                        const LoginSecureNote(embedded: true),
                                        LoginFooterLink(
                                          embedded: true,
                                          onCreateAccount: () =>
                                              context.push(AppRoutes.register),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCompactHero extends StatelessWidget {
  const _LoginCompactHero();

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.14),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: const Icon(
                Icons.water_drop_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.appName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    strings.loginTagline,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const LanguageSelectorButton(dark: true),
          ],
        ),
      ),
    );
  }
}
