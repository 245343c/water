import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/widgets/home_delivery_choice.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/auth_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/more/widgets/settings_screen_widgets.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerController = TextEditingController();
  final _businessController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _normalPriceController = TextEditingController(text: '20');
  final _coolPriceController = TextEditingController(text: '30');
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _homeDelivery = true;

  @override
  void dispose() {
    _ownerController.dispose();
    _businessController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _normalPriceController.dispose();
    _coolPriceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthRepository>();
    final error = await auth.registerAsync(
      ownerName: _ownerController.text,
      businessName: _businessController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
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

    final normal = double.tryParse(_normalPriceController.text) ?? 20;
    final cool = double.tryParse(_coolPriceController.text) ?? 30;

    final repo = context.read<WaterPlantRepository>();
    repo.updateSettings(
      repo.settings.copyWith(
        businessName: _businessController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        normalPrice: normal,
        coolPrice: cool,
        homeDeliveryAvailable: _homeDelivery,
      ),
    );

    if (!mounted) return;
    if (!_homeDelivery) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Account created. Your shop is hidden from customers until you enable home delivery in Settings.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Create shop account',
      subtitle: 'Set up your water plant on the platform',
      onBack: () => context.pop(),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const SettingsSectionLabel(title: 'Your account'),
            AuthFormCard(
              children: [
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Your name',
                  controller: _ownerController,
                  hint: 'Owner / manager name',
                  icon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  required: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                AuthTextField(
                  label: 'Email',
                  controller: _emailController,
                  hint: 'you@business.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                AuthTextField(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Min. 6 characters',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  required: true,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AuthColors.labelGrey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                AuthTextField(
                  label: 'Confirm password',
                  controller: _confirmController,
                  hint: 'Re-enter password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  required: true,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AuthColors.labelGrey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
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
            const SettingsSectionLabel(
              title: 'Shop details',
              subtitle: 'Shown to customers only if home delivery is enabled',
            ),
            AuthFormCard(
              children: [
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Business name',
                  controller: _businessController,
                  hint: 'Sri Sai RO Water Plant',
                  icon: Icons.storefront_outlined,
                  textCapitalization: TextCapitalization.words,
                  required: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Business name is required'
                      : null,
                ),
                AuthTextField(
                  label: 'Shop address',
                  controller: _addressController,
                  hint: 'Full address with city',
                  icon: Icons.location_on_outlined,
                  textCapitalization: TextCapitalization.sentences,
                  required: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().length < 8 ? 'Enter full address' : null,
                ),
                AuthTextField(
                  label: 'Phone number',
                  controller: _phoneController,
                  hint: '10-digit mobile',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  required: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 10) return 'Valid phone required';
                    return null;
                  },
                ),
                AuthTextField(
                  label: 'Normal can price (₹)',
                  controller: _normalPriceController,
                  hint: '20',
                  icon: Icons.water_drop_outlined,
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter valid price';
                    return null;
                  },
                ),
                AuthTextField(
                  label: 'Cool can price (₹)',
                  controller: _coolPriceController,
                  hint: '30',
                  icon: Icons.ac_unit_outlined,
                  keyboardType: TextInputType.number,
                  required: true,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter valid price';
                    return null;
                  },
                ),
              ],
            ),
            const SettingsSectionLabel(
              title: 'Customer app visibility',
            ),
            AuthFormCard(
              children: [
                const SizedBox(height: 16),
                HomeDeliveryChoice(
                  value: _homeDelivery,
                  onChanged: (v) => setState(() => _homeDelivery = v),
                ),
                const SizedBox(height: 16),
              ],
            ),
            AuthPrimaryButton(
              label: 'Create account',
              loading: _loading,
              onPressed: _submit,
            ),
            AuthFooterLink(
              prompt: 'Already have an account? ',
              actionLabel: 'Sign in',
              onTap: () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
