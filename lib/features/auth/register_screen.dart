import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/input_validators.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const double _defaultNormalPrice = 20;
  static const double _defaultCoolPrice = 30;

  final _formKey = GlobalKey<FormState>();
  final _ownerController = TextEditingController();
  final _businessController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  final bool _homeDelivery = true;
  bool _otpSent = false;

  @override
  void dispose() {
    _ownerController.dispose();
    _businessController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthRepository>();
    final error = _otpSent
        ? await auth.completeAdminRegistrationWithOtp(
            ownerName: _ownerController.text,
            businessName: _businessController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            password: _passwordController.text,
            address: _addressController.text,
            normalPrice: _defaultNormalPrice,
            coolPrice: _defaultCoolPrice,
            homeDeliveryAvailable: _homeDelivery,
            otp: _otpController.text,
          )
        : await auth.requestAdminRegistrationOtp(
            phone: _phoneController.text,
            email: _emailController.text,
          );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.poppins()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_otpSent) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP sent to ${_phoneController.text.trim()}',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    const message =
        'Account created. Sign in with your mobile number and password.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomersColors.screenBg,
      body: AddEditCustomerScaffold(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AddEditCustomerHeader(
                title: 'Create account',
                subtitle: 'New shop setup',
                onBack: () => context.pop(),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 16),
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF1A73E8).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.celebration_rounded,
                              color: Color(0xFF1A73E8),
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '30-day free trial · Full admin + driver access. No card required today.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AddEditCustomerColors.titleNavy,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AddEditCustomerSectionCard(
                        title: 'Your account',
                        child: Column(
                          children: [
                            AddEditCustomerField(
                              label: 'Your name',
                              controller: _ownerController,
                              hint: 'Owner / manager name',
                              icon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                            AddEditCustomerField(
                              label: 'Email (optional)',
                              controller: _emailController,
                              hint: 'For receipt / support, optional',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: InputValidators.optionalEmail,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                            ),
                            AddEditCustomerField(
                              label: 'Password',
                              controller: _passwordController,
                              hint: 'Min. 6 characters',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              required: true,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AddEditCustomerColors.labelGrey,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            AddEditCustomerField(
                              label: 'Confirm password',
                              controller: _confirmController,
                              hint: 'Re-enter password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscureConfirm,
                              required: true,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AddEditCustomerColors.labelGrey,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                              validator: (v) {
                                if (v != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AddEditCustomerSectionCard(
                        title: 'Shop details',
                        child: Column(
                          children: [
                            AddEditCustomerField(
                              label: 'Business name',
                              controller: _businessController,
                              hint: 'Sri Sai RO Water Plant',
                              icon: Icons.storefront_outlined,
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Business name is required'
                                  : null,
                            ),
                            AddEditCustomerField(
                              label: 'Shop address',
                              controller: _addressController,
                              hint: 'Full address with city',
                              icon: Icons.home_outlined,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 2,
                              required: true,
                              validator: (v) => v == null || v.trim().length < 8
                                  ? 'Enter full address'
                                  : null,
                            ),
                            AddEditCustomerField(
                              label: 'Phone number',
                              controller: _phoneController,
                              hint: '10-digit mobile',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              required: true,
                              validator: InputValidators.requiredIndianMobile,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_otpSent) ...[
                        AddEditCustomerSectionCard(
                          title: 'Verify mobile',
                          subtitle:
                              'Enter the OTP sent to ${_phoneController.text.trim()}',
                          child: AddEditCustomerField(
                            label: 'Mobile OTP',
                            controller: _otpController,
                            hint: 'Enter verification code',
                            icon: Icons.verified_user_outlined,
                            keyboardType: TextInputType.number,
                            required: true,
                            validator: (v) {
                              if (!_otpSent) return null;
                              if (v == null || v.trim().length < 4) {
                                return 'Enter OTP';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AddEditCustomerColors.labelGrey,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: Text(
                              'Sign in',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AddEditCustomerColors.primaryBtn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AddEditCustomerSaveButton(
                label: _otpSent ? 'Verify OTP & create account' : 'Send OTP',
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
