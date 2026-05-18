import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/login_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

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
    final error = auth.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return LoginPremiumScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LoginHeroSection(),
              LoginFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LoginTextField(
                      label: 'Email',
                      controller: _emailController,
                      hint: 'you@business.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    LoginTextField(
                      label: 'Password',
                      controller: _passwordController,
                      hint: 'Enter password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: LoginColors.labelGrey,
                          size: 22,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Password is required' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(right: 4, bottom: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: LoginColors.primaryBtn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const LoginDemoBox(),
              LoginSignInButton(
                loading: _loading,
                onPressed: _submit,
              ),
              const LoginSecureNote(),
              LoginFooterLink(
                onCreateAccount: () => context.push(AppRoutes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
