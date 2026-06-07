import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/utils/input_validators.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await context.read<AuthRepository>().requestPasswordReset(
      _emailController.text,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = error == null;
    });
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Reset password',
      subtitle: 'We will send a reset link to your email',
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
                    validator: InputValidators.requiredEmail,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                ],
              ),
              const AuthInfoBanner(
                tint: BannerTint.orange,
                message:
                    'For security we never confirm whether an email exists.',
              ),
              AuthPrimaryButton(
                label: 'Send reset link',
                loading: _loading,
                onPressed: _sendCode,
              ),
            ] else ...[
              const AuthInfoBanner(
                tint: BannerTint.green,
                message:
                    'If this email is registered, a password reset link has been sent. Check your inbox and spam folder.',
              ),
              AuthPrimaryButton(
                label: 'Back to sign in',
                onPressed: () => context.go(AppRoutes.login),
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
