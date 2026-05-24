import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class DriversColors {
  static const Color screenBg = AppColors.surface;
  static const Color titleNavy = AppColors.textPrimary;
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = AppColors.cardBorder;
  static const Color accent = AppColors.primary;
  static const Color warning = Color(0xFFD97706);

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: cardBorder),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class DriversScaffold extends StatelessWidget {
  const DriversScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PremiumResponsiveBody(maxWidth: 1180, child: child),
    );
  }
}

class DriversHeader extends StatelessWidget {
  const DriversHeader({super.key, required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AdminPageHeader(
      title: 'Drivers',
      subtitle: 'Team access and delivery staff',
      onBack: onBack,
      trailing: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: Text(
          'Add',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class AddDriverResult {
  const AddDriverResult({
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String name;
  final String phone;
  final String email;
  final String password;
}

class AddDriverSheet extends StatefulWidget {
  const AddDriverSheet({super.key});

  @override
  State<AddDriverSheet> createState() => _AddDriverSheetState();
}

class _AddDriverSheetState extends State<AddDriverSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      AddDriverResult(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: DriversColors.cardDecoration.copyWith(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add driver',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: DriversColors.titleNavy,
                  ),
                ),
                Text(
                  'Create login credentials for the driver app',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: DriversColors.labelGrey,
                  ),
                ),
                const SizedBox(height: 16),
                _field(_name, 'Full name', Icons.person_outline),
                const SizedBox(height: 12),
                _field(
                  _phone,
                  'Phone',
                  Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _field(
                  _email,
                  'Login email',
                  Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _field(
                  _password,
                  'Password (min 6)',
                  Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: DriversColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create driver',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (label.contains('Password') && v.length < 6) {
          return 'Min 6 characters';
        }
        if (label.contains('email') && !v.contains('@')) return 'Invalid email';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: DriversColors.accent, size: 22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
