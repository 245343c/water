import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _demoOtp;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _snack('Enter a valid 10-digit mobile number');
      return;
    }
    setState(() => _loading = true);
    final otp = context.read<AuthRepository>().requestCustomerOtp(phone);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _otpSent = otp != null;
      _demoOtp = otp;
    });
    if (otp == null) {
      _snack('Could not send OTP');
      return;
    }
    _snack('OTP sent (demo: $otp)');
  }

  Future<void> _verify() async {
    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();
    setState(() => _loading = true);
    final error = auth.verifyCustomerOtp(
      phone: _phoneController.text,
      otp: _otpController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      _snack(error);
      return;
    }
    final user = auth.currentUser!;
    repo.linkContractCustomerOnLogin(userId: user.id, phone: user.phone);

    final isContract = repo.isMonthlyContractAppUser(user.id, phone: user.phone);
    if (isContract) {
      final crm = repo.linkedCrmCustomerForAppUser(user.id);
      auth.markCustomerOnboardingComplete(
        user.id,
        name: crm?.name ?? user.ownerName,
      );
    }

    final profile = repo.customerProfileByUserId(user.id);
    final needsOnboarding = !isContract &&
        (!user.customerProfileComplete ||
            profile == null ||
            !profile.onboardingComplete);
    context.go(needsOnboarding ? AppRoutes.customerOnboarding : AppRoutes.customerHome);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomerColors.screenBg,
      body: CustomerScaffold(
        child: Column(
          children: [
            CustomerHeader(
              title: 'Sign in',
              subtitle: 'OTP on your mobile · Bulk customers use shop-registered number',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.welcome),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: CustomerColors.cardDecoration,
                    child: Column(
                      children: [
                        CustomerTextField(
                          label: 'Mobile number',
                          controller: _phoneController,
                          hint: '9876543210 (retail) or 9632580741 (bulk)',
                          icon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        if (_otpSent) ...[
                          CustomerTextField(
                            label: 'OTP code',
                            controller: _otpController,
                            hint: '6 digits',
                            icon: Icons.sms_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          if (_demoOtp != null)
                            Text(
                              'Demo OTP: $_demoOtp',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: CustomerColors.accent,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomerPrimaryButton(
                    label: _otpSent ? 'Verify & continue' : 'Send OTP',
                    loading: _loading,
                    icon: _otpSent ? Icons.verified_rounded : Icons.send_rounded,
                    onPressed: _otpSent ? _verify : _sendOtp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
