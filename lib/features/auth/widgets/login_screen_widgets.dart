import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Full-screen background matching the reference mockup.
class LoginPremiumBackground extends StatelessWidget {
  const LoginPremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: LoginColors.pageBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 148,
            child: _TopWaveHeader(),
          ),
          Positioned(
            left: 12,
            top: 168,
            child: Opacity(
              opacity: 0.22,
              child: CustomPaint(
                size: const Size(88, 56),
                painter: _SideWaterLinesPainter(),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 175,
            child: Opacity(
              opacity: 0.14,
              child: Icon(
                Icons.local_shipping_outlined,
                size: 88,
                color: LoginColors.brandNavy.withValues(alpha: 0.7),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 88,
            child: _BottomSoftWaves(),
          ),
        ],
      ),
    );
  }
}

class _TopWaveHeader extends StatelessWidget {
  const _TopWaveHeader();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _TopWavePainter(), size: Size.infinite);
  }
}

class _TopWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final deep = Paint()..color = const Color(0xFF1E40AF);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.52)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.98,
        size.width * 0.28,
        size.height * 0.42,
        0,
        size.height * 0.62,
      )
      ..close();
    canvas.drawPath(path, deep);

    final accent = Paint()..color = LoginColors.brandBlue.withValues(alpha: 0.92);
    final path2 = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.88,
        size.width * 0.58,
        size.height * 0.72,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SideWaterLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = LoginColors.brandBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.22 + i * 0.28);
      final path = Path();
      for (var x = 0.0; x <= size.width; x += 2) {
        final waveY = y + math.sin((x / size.width) * math.pi * 2.2) * 5;
        if (x == 0) {
          path.moveTo(x, waveY);
        } else {
          path.lineTo(x, waveY);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomSoftWaves extends StatelessWidget {
  const _BottomSoftWaves();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BottomWavesPainter(), size: Size.infinite);
  }
}

class _BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w1 = Paint()..color = Colors.white.withValues(alpha: 0.7);
    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.08, size.width, size.height * 0.32)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path1, w1);

    final w2 = Paint()..color = const Color(0xFFDBEAFE).withValues(alpha: 0.55);
    final path2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.42, size.height * 0.28, size.width, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path2, w2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  const LoginBrandHeader({super.key, this.businessName = 'Sri Sai RO Water Plant'});

  final String businessName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 52),
          Text(
            businessName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: LoginColors.brandNavy,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: LoginColors.brandBlue.withValues(alpha: 0.3)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.water_drop, size: 13, color: LoginColors.brandBlue),
              ),
              Expanded(
                child: Container(height: 1, color: LoginColors.brandBlue.withValues(alpha: 0.3)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome back',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: LoginColors.brandNavy,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to manage deliveries,\ncustomers, and billing',
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
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LoginColors.fieldBorder.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: LoginColors.brandNavy.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
              children: const [
                TextSpan(text: ' *', style: TextStyle(color: LoginColors.requiredRed)),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: LoginColors.labelGrey),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: icon != null
                  ? Icon(icon, size: 20, color: LoginColors.brandBlue)
                  : null,
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LoginColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LoginColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LoginColors.primaryBtn, width: 1.5),
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

class LoginDemoBox extends StatelessWidget {
  const LoginDemoBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: LoginColors.brandBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, size: 16, color: LoginColors.brandBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo: admin@srisai.com • Password: admin123',
              style: GoogleFonts.poppins(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: LoginColors.brandNavy,
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
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Material(
        elevation: 3,
        shadowColor: LoginColors.primaryBtn.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        color: LoginColors.primaryBtn,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFF2563EB)],
              ),
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sign in',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class LoginSecureNote extends StatelessWidget {
  const LoginSecureNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 14, color: LoginColors.brandBlue.withValues(alpha: 0.75)),
          const SizedBox(width: 6),
          Text(
            'Secured sign-in',
            style: GoogleFonts.poppins(fontSize: 12, color: LoginColors.labelGrey),
          ),
        ],
      ),
    );
  }
}

class LoginFooterLink extends StatelessWidget {
  const LoginFooterLink({super.key, required this.onCreateAccount});

  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'New here? ',
            style: GoogleFonts.poppins(fontSize: 13, color: LoginColors.labelGrey),
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
  const LoginPremiumScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: LoginColors.pageBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const LoginPremiumBackground(),
            SafeArea(
              bottom: false,
              child: child,
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
        Positioned(
          top: 0,
          child: LoginLogoBadge(),
        ),
      ],
    );
  }
}
