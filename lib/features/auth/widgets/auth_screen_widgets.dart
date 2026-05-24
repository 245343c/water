import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class AuthColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color fieldFill = Color(0xFFF9FAFB);
  static const Color primaryBtn = Color(0xFF1A73E8);
}

/// Production auth shell — compact navy header + gray body (matches Customers).
class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: CustomersColors.screenBg,
        body: PremiumResponsiveBody(
          maxWidth: 720,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthCompactHeader(
                title: title,
                subtitle: subtitle,
                onBack: onBack,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthCompactHeader extends StatelessWidget {
  const AuthCompactHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: CustomersColors.headerGradient,
      padding: EdgeInsets.fromLTRB(onBack != null ? 4 : 20, top + 8, 20, 20),
      child: onBack != null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: onBack,
                ),
                Expanded(
                  child: _TitleBlock(title: title, subtitle: subtitle),
                ),
                const SizedBox(width: 48),
              ],
            )
          : _TitleBlock(title: title, subtitle: subtitle),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthColors.fieldBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.validator,
    this.required = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffix,
    this.inCard = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool required;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffix;
  final bool inCard;

  @override
  Widget build(BuildContext context) {
    final horizontal = inCard ? 16.0 : 0.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AuthColors.titleNavy,
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CustomersColors.balanceRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AuthColors.titleNavy,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: AuthColors.labelGrey,
              ),
              filled: true,
              fillColor: AuthColors.fieldFill,
              prefixIcon: icon != null
                  ? Icon(icon, size: 20, color: AuthColors.labelGrey)
                  : null,
              suffixIcon: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AuthColors.primaryBtn,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CustomersColors.balanceRed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AuthColors.primaryBtn,
            disabledBackgroundColor: AuthColors.primaryBtn.withValues(
              alpha: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            prompt,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AuthColors.labelGrey,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AuthColors.primaryBtn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTrustNote extends StatelessWidget {
  const AuthTrustNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 14,
            color: AuthColors.labelGrey.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            'Secured sign-in',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AuthColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthDemoHint extends StatelessWidget {
  const AuthDemoHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Admin accounts now use Firebase sign in.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.35,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({
    super.key,
    required this.message,
    this.tint = BannerTint.blue,
  });

  final String message;
  final BannerTint tint;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tint) {
      BannerTint.blue => (
        bg: const Color(0xFFEFF6FF),
        border: const Color(0xFFBFDBFE),
        text: const Color(0xFF1D4ED8),
      ),
      BannerTint.green => (
        bg: const Color(0xFFECFDF5),
        border: const Color(0xFF86EFAC),
        text: const Color(0xFF166534),
      ),
      BannerTint.orange => (
        bg: const Color(0xFFFFF7ED),
        border: const Color(0xFFFED7AA),
        text: const Color(0xFF9A3412),
      ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 12,
          height: 1.45,
          color: colors.text,
        ),
      ),
    );
  }
}

enum BannerTint { blue, green, orange }

class AuthOtpDisplayCard extends StatelessWidget {
  const AuthOtpDisplayCard({super.key, required this.otp});

  final String otp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthColors.fieldBorder),
      ),
      child: Column(
        children: [
          Text(
            'Verification code (demo)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthColors.labelGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            otp,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
              color: AuthColors.titleNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'In production this is sent to email only',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              height: 1.35,
              color: AuthColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}
