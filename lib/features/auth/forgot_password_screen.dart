import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/auth_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _demoOtp;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthRepository>();
    final demoOtp = await auth.requestPasswordResetAsync(_emailController.text);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
      _demoOtp = demoOtp;
    });
  }

  void _continueToReset() {
    final email = Uri.encodeComponent(_emailController.text.trim());
    context.push('${AppRoutes.resetPassword}?email=$email');
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Reset password',
      subtitle: 'We’ll send a code to your email',
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (!_sent) ...[
              AuthFormCard(
                children: [
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Registered email',
                    controller: _emailController,
                    hint: 'you@business.com',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    required: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _sendCode(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                ],
              ),
              const AuthInfoBanner(
                tint: BannerTint.orange,
                message:
                    'For security we never confirm whether an email exists. Codes expire in 10 minutes.',
              ),
              AuthPrimaryButton(
                label: 'Send reset code',
                loading: _loading,
                onPressed: _sendCode,
              ),
            ] else ...[
              const AuthInfoBanner(
                tint: BannerTint.green,
                message:
                    'If this email is registered, a reset code has been sent. Check your inbox and spam folder.',
              ),
              if (_demoOtp != null) AuthOtpDisplayCard(otp: _demoOtp!),
              AuthPrimaryButton(
                label: 'Enter code & new password',
                onPressed: _continueToReset,
              ),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : _sendCode,
                  child: Text(
                    'Resend code',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AuthColors.primaryBtn,
                    ),
                  ),
                ),
              ),
            ],
            AuthFooterLink(
              prompt: 'Remember password? ',
              actionLabel: 'Sign in',
              onTap: () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
