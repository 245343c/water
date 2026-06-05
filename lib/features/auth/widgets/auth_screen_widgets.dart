import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/features/auth/widgets/login_screen_widgets.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class AuthColors {
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color fieldFill = Color(0xFFF9FAFB);
  static const Color primaryBtn = Color(0xFF1A73E8);
}

/// Premium auth shell — matches staff login (navy gradient + floating cards).
class AuthPremiumScreenLayout extends StatelessWidget {
  const AuthPremiumScreenLayout({
    super.key,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.child,
    this.onBack,
    this.heroIcon = Icons.water_drop_rounded,
  });

  final String heroTitle;
  final String heroSubtitle;
  final IconData heroIcon;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF001F3F),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const LoginPremiumBackground(variant: LoginBackgroundVariant.auth),
            SafeArea(
              bottom: false,
              child: PremiumResponsiveBody(
                maxWidth: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onBack != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6, top: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: onBack,
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    _AuthPremiumHero(
                      title: heroTitle,
                      subtitle: heroSubtitle,
                      icon: heroIcon,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 28),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPremiumHero extends StatelessWidget {
  const _AuthPremiumHero({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    subtitle,
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
          ],
        ),
      ),
    );
  }
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
  const AuthFormCard({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.premium = false,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    if (premium) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF001F3F).withValues(alpha: 0.28),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LoginColors.brandNavy,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AuthColors.labelGrey,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              ...children,
            ],
          ),
        ),
      );
    }

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
    this.premium = false,
    this.maxLines = 1,
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
  final bool premium;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final horizontal = inCard && !premium ? 16.0 : 0.0;
    final labelStyle = GoogleFonts.poppins(
      fontSize: premium ? 12 : 13,
      fontWeight: FontWeight.w600,
      color: premium ? const Color(0xFF374151) : AuthColors.titleNavy,
      letterSpacing: premium ? 0.1 : 0,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, premium ? 14 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: labelStyle,
              children: required
                  ? [
                      TextSpan(
                        text: ' *',
                        style: labelStyle.copyWith(
                          color: CustomersColors.balanceRed,
                        ),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: GoogleFonts.poppins(
              fontSize: premium ? 14 : 15,
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
              fillColor: premium ? Colors.white : AuthColors.fieldFill,
              prefixIcon: icon != null
                  ? premium
                      ? Padding(
                          padding: const EdgeInsets.only(left: 10, right: 4),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AuthColors.primaryBtn.withValues(
                                alpha: 0.09,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: AuthColors.primaryBtn,
                            ),
                          ),
                        )
                      : Icon(icon, size: 20, color: AuthColors.labelGrey)
                  : null,
              prefixIconConstraints: premium
                  ? const BoxConstraints(minWidth: 52, minHeight: 48)
                  : null,
              suffixIcon: suffix,
              contentPadding: premium
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 15)
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(premium ? 14 : 12),
                borderSide: const BorderSide(color: AuthColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(premium ? 14 : 12),
                borderSide: const BorderSide(color: AuthColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(premium ? 14 : 12),
                borderSide: const BorderSide(
                  color: AuthColors.primaryBtn,
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(premium ? 14 : 12),
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
    this.premium = false,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool premium;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (premium) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Material(
          elevation: 4,
          shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: loading
                      ? [
                          AuthColors.primaryBtn.withValues(alpha: 0.5),
                          AuthColors.primaryBtn.withValues(alpha: 0.5),
                        ]
                      : const [
                          Color(0xFF1E40AF),
                          Color(0xFF2563EB),
                          Color(0xFF3B82F6),
                        ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: loading
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(icon, color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }

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
      margin: const EdgeInsets.only(bottom: 12),
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
