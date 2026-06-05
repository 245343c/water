import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';

abstract final class LoginColors {
  static const Color brandNavy = Color(0xFF1E3A8A);
  static const Color brandBlue = Color(0xFF2563EB);
  static const Color headerBlue = Color(0xFF1D4ED8);
  static const Color primaryBtn = Color(0xFF1A73E8);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color fieldBorder = Color(0xFFE5E7EB);
  static const Color requiredRed = Color(0xFFDC2626);
  static const Color pageBg = Color(0xFFF4F9FD);
}

/// Background style — welcome is clean; auth keeps form-focused decor.
enum LoginBackgroundVariant { welcome, auth }

/// Full-screen background for login / welcome flows.
class LoginPremiumBackground extends StatelessWidget {
  const LoginPremiumBackground({
    super.key,
    this.variant = LoginBackgroundVariant.auth,
  });

  final LoginBackgroundVariant variant;

  @override
  Widget build(BuildContext context) {
    if (variant == LoginBackgroundVariant.welcome) {
      return const _WelcomeCleanBackground();
    }

    return const _AuthPremiumBackground();
  }
}

/// Staff login — navy brand gradient, soft glows, abstract water curves.
class _AuthPremiumBackground extends StatelessWidget {
  const _AuthPremiumBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF001F3F),
            Color(0xFF0B2F5C),
            Color(0xFF1E3A8A),
            Color(0xFF1D4ED8),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              size: 220,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 140,
            left: -70,
            child: _GlowOrb(
              size: 180,
              color: const Color(0xFF60A5FA).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: CustomPaint(painter: _AuthWaterCurvePainter()),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 120,
            child: CustomPaint(painter: _AuthTopShinePainter()),
          ),
        ],
      ),
    );
  }
}

class _AuthWaterCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wave1 = Path()
      ..moveTo(0, h * 0.35)
      ..quadraticBezierTo(w * 0.35, h * 0.18, w * 0.7, h * 0.32)
      ..quadraticBezierTo(w * 0.92, h * 0.42, w, h * 0.28)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wave1,
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );

    final wave2 = Path()
      ..moveTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.45, h * 0.38, w, h * 0.52)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wave2,
      Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.07),
    );

    final wave3 = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.55, h * 0.58, w, h * 0.7)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      wave3,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthTopShinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shine = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shine);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.55),
      Offset(size.width * 0.42, size.height * 0.2),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Premium welcome — soft gradient, no clipart truck or side waves.
class _WelcomeCleanBackground extends StatelessWidget {
  const _WelcomeCleanBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8F2FC), Color(0xFFF6FAFE), Color(0xFFFFFFFF)],
          stops: [0.0, 0.42, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: _WelcomeHeaderCurve(),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: _GlowOrb(
              size: 160,
              color: LoginColors.brandBlue.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            top: 120,
            left: -50,
            child: _GlowOrb(
              size: 120,
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: CustomPaint(painter: _WelcomeBottomFadePainter()),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeaderCurve extends StatelessWidget {
  const _WelcomeHeaderCurve();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WelcomeHeaderPainter(), size: Size.infinite);
  }
}

class _WelcomeHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [Color(0xFF001F3F), Color(0xFF1E3A8A), Color(0xFF2563EB)],
    );
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.95,
        0,
        size.height * 0.78,
      )
      ..close();
    canvas.drawPath(path, Paint()..shader = gradient.createShader(rect));

    final shine = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.35),
      Offset(size.width * 0.55, size.height * 0.2),
      shine,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WelcomeBottomFadePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFDBEAFE).withValues(alpha: 0.0),
          const Color(0xFFDBEAFE).withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Logo badge overlapping the blue wave (reference layout).
class LoginLogoBadge extends StatelessWidget {
  const LoginLogoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: LoginColors.brandBlue.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.water_drop_rounded,
            size: 46,
            color: LoginColors.brandBlue,
          ),
          Positioned(
            bottom: 14,
            child: CustomPaint(
              size: const Size(36, 10),
              painter: _LogoWaveAccentPainter(),
            ),
          ),
          Positioned(
            top: 22,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoWaveAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LoginColors.brandBlue.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height * 2),
      0.1,
      math.pi - 0.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Business name + welcome (logo rendered separately in stack).
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({
    super.key,
    this.businessName = 'Staff portal',
    this.title = 'Welcome back',
    this.subtitle = 'Sign in to manage deliveries,\ncustomers, and billing',
    this.compact = false,
  });

  final String businessName;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        children: [
          SizedBox(height: compact ? 56 : 52),
          Text(
            businessName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: compact ? 16 : 17,
              fontWeight: FontWeight.w700,
              color: LoginColors.brandNavy,
              letterSpacing: -0.2,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: LoginColors.brandBlue.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.water_drop,
                    size: 13,
                    color: LoginColors.brandBlue,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: LoginColors.brandBlue.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: compact ? 12 : 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: compact ? 26 : 28,
              fontWeight: FontWeight.w700,
              color: LoginColors.brandNavy,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.45,
              color: LoginColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LoginAuthCard(child: child);
  }
}

/// Floating sign-in card on navy background.
class LoginAuthCard extends StatelessWidget {
  const LoginAuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.95),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001F3F).withValues(alpha: 0.32),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: LoginColors.brandBlue.withValues(alpha: 0.06),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Admin / driver hint chips under sign-in title.
class LoginRoleHintRow extends StatelessWidget {
  const LoginRoleHintRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LoginRoleChip(
          icon: Icons.storefront_outlined,
          label: 'Shop owner',
        ),
        SizedBox(width: 8),
        _LoginRoleChip(
          icon: Icons.local_shipping_outlined,
          label: 'Driver',
        ),
      ],
    );
  }
}

class _LoginRoleChip extends StatelessWidget {
  const _LoginRoleChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LoginColors.brandBlue.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LoginColors.brandBlue),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: LoginColors.brandNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
                letterSpacing: 0.1,
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: LoginColors.requiredRed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: LoginColors.brandNavy,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: LoginColors.labelGrey,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 10, right: 4),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: LoginColors.brandBlue.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: LoginColors.brandBlue,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 52,
                minHeight: 48,
              ),
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: LoginColors.fieldBorder.withValues(alpha: 0.9),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: LoginColors.fieldBorder.withValues(alpha: 0.9),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: LoginColors.primaryBtn,
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LoginColors.requiredRed),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginSignInButton extends StatelessWidget {
  const LoginSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.embedded = false,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      elevation: embedded ? 4 : 3,
      shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF2563EB).withValues(alpha: 0.25),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                        'Sign in',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    if (embedded) return button;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: button,
    );
  }
}

class LoginSecureNote extends StatelessWidget {
  const LoginSecureNote({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: embedded ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 14,
            color: LoginColors.brandBlue.withValues(alpha: 0.75),
          ),
          const SizedBox(width: 6),
          Text(
            'Secured sign-in',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: LoginColors.labelGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginFooterLink extends StatelessWidget {
  const LoginFooterLink({
    super.key,
    required this.onCreateAccount,
    this.embedded = false,
  });

  final VoidCallback onCreateAccount;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        embedded ? 0 : 20,
        embedded ? 12 : 16,
        embedded ? 0 : 20,
        embedded ? 4 : 28,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'New here? ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: LoginColors.labelGrey,
            ),
          ),
          GestureDetector(
            onTap: onCreateAccount,
            child: Text(
              'Create account',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LoginColors.primaryBtn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPremiumScaffold extends StatelessWidget {
  const LoginPremiumScaffold({
    super.key,
    required this.child,
    this.backgroundVariant = LoginBackgroundVariant.auth,
  });

  final Widget child;
  final LoginBackgroundVariant backgroundVariant;

  @override
  Widget build(BuildContext context) {
    final isWelcome = backgroundVariant == LoginBackgroundVariant.welcome;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isWelcome
            ? const Color(0xFFF6FAFE)
            : const Color(0xFF001F3F),
        body: Stack(
          fit: StackFit.expand,
          children: [
            LoginPremiumBackground(variant: backgroundVariant),
            SafeArea(
              bottom: false,
              child: PremiumResponsiveBody(
                maxWidth: isWelcome ? 920 : 720,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo + brand text stacked like the reference (logo overlaps wave).
class LoginHeroSection extends StatelessWidget {
  const LoginHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: const [
        LoginBrandHeader(),
        Positioned(top: 0, child: LoginLogoBadge()),
      ],
    );
  }
}

/// Welcome / role picker hero — correct copy, no staff-only messaging.
class WelcomeHeroSection extends StatelessWidget {
  const WelcomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: const [
        LoginBrandHeader(
          title: 'Welcome',
          subtitle: 'Order fresh RO water at home\nor sign in to run your shop',
          compact: true,
        ),
        Positioned(top: 4, child: LoginLogoBadge()),
      ],
    );
  }
}
