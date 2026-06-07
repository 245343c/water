import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/services/push_notification_service.dart';
import 'package:sri_sai_ro_water/core/utils/input_validators.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/auth_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/login_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (!InputValidators.isValidIndianMobile(phone)) {
      _snack('Enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _loading = true);
    final error = await context.read<AuthRepository>().requestCustomerOtp(
      phone,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      _otpSent = error == null;
    });

    if (error != null) {
      _snack(error);
      return;
    }
    _snack('OTP sent. Check your mobile.');
  }

  Future<void> _verify() async {
    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();

    setState(() => _loading = true);
    String? error;
    try {
      error = await auth.verifyCustomerOtp(
        phone: _phoneController.text,
        otp: _otpController.text,
      );
    } on FirebaseException catch (e) {
      error = 'OTP sign-in failed: ${e.message ?? e.code}';
    } catch (_) {
      error = 'OTP sign-in failed. Please try again';
    }

    setState(() => _loading = false);
    if (!mounted) return;
    if (error != null) {
      _snack(error);
      return;
    }

    final user = auth.currentUser!;
    setState(() => _loading = true);
    try {
      await repo.linkContractCustomerOnLoginFromFirestore(
        userId: user.id,
        phone: user.phone,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Customer link failed: ${e.message ?? e.code}');
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Customer link failed. Please try again');
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    final isContract = repo.isMonthlyContractAppUser(
      user.id,
      phone: user.phone,
    );
    final crm = repo.linkedCrmCustomerForAppUser(user.id);
    if (crm == null) {
      await context.read<PushNotificationService>().unregisterCurrentToken();
      await auth.logout();
      if (!mounted) return;
      _snack('This mobile number is not added by a water plant admin.');
      return;
    }

    auth.markCustomerOnboardingComplete(user.id, name: crm.name);

    final profile = repo.customerProfileByUserId(user.id);
    final currentUser = auth.currentUser ?? user;
    final needsOnboarding =
        !isContract &&
        (!currentUser.customerProfileComplete ||
            profile == null ||
            !profile.onboardingComplete);
    context.go(
      needsOnboarding ? AppRoutes.customerOnboarding : AppRoutes.customerHome,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPremiumScreenLayout(
      heroTitle: 'Order pure water',
      heroSubtitle: 'Home delivery · Fresh RO water · Fast and reliable',
      heroIcon: Icons.water_drop_rounded,
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use the mobile number added by your water plant',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          LoginAuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _otpSent ? 'Enter OTP' : 'Mobile number',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: LoginColors.brandNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _otpSent
                        ? 'We sent a code to ${_phoneController.text.trim()}'
                        : 'Receive a one-time code to sign in',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: LoginColors.labelGrey,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoginTextField(
                    label: 'Mobile number',
                    controller: _phoneController,
                    hint: '9876543210',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: InputValidators.requiredIndianMobile,
                  ),
                  if (_otpSent) ...[
                    LoginTextField(
                      label: 'OTP code',
                      controller: _otpController,
                      hint: '6-digit code',
                      icon: Icons.sms_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _verify(),
                      validator: (v) {
                        if (v == null || v.trim().length < 4) {
                          return 'Enter the OTP code';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 6),
                  AuthPrimaryButton(
                    premium: true,
                    label: _otpSent ? 'Verify & continue' : 'Send OTP',
                    icon: _otpSent
                        ? Icons.verified_rounded
                        : Icons.send_rounded,
                    loading: _loading,
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      if (_otpSent) {
                        _verify();
                      } else {
                        _sendOtp();
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      'Your admin must add this number before you can sign in.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: LoginColors.labelGrey,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
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
