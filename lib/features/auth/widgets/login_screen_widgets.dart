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

    return const ColoredBox(
      color: LoginColors.pageBg,
      child: CustomPaint(
        painter: _StaffDeliveryScenePainter(),
        size: Size.infinite,
      ),
    );
  }
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
          colors: [
            Color(0xFFE8F2FC),
            Color(0xFFF6FAFE),
            Color(0xFFFFFFFF),
          ],
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
      colors: const [
        Color(0xFF001F3F),
        Color(0xFF1E3A8A),
        Color(0xFF2563EB),
      ],
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

/// Staff login — water plant (left), delivery van + cans (right), sky & waves.
class _StaffDeliveryScenePainter extends CustomPainter {
  const _StaffDeliveryScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky
    final skyRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C4A6E),
            Color(0xFF1E40AF),
            Color(0xFF3B82F6),
            Color(0xFFBAE6FD),
            Color(0xFFE0F2FE),
          ],
          stops: [0.0, 0.22, 0.42, 0.72, 1.0],
        ).createShader(skyRect),
    );

    // Sun glow
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.12),
      42,
      Paint()..color = const Color(0xFFFDE68A).withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.12),
      24,
      Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.7),
    );

    // Distant hills
    final hill = Paint()..color = const Color(0xFF1E3A8A).withValues(alpha: 0.35);
    final hillPath = Path()
      ..moveTo(0, h * 0.38)
      ..quadraticBezierTo(w * 0.25, h * 0.32, w * 0.5, h * 0.36)
      ..quadraticBezierTo(w * 0.75, h * 0.4, w, h * 0.34)
      ..lineTo(w, h * 0.5)
      ..lineTo(0, h * 0.48)
      ..close();
    canvas.drawPath(hillPath, hill);

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.48, w, h * 0.52),
      Paint()..color = const Color(0xFFDCFCE7),
    );

    // Road
    final roadY = h * 0.62;
    canvas.drawRect(
      Rect.fromLTWH(0, roadY, w, h * 0.12),
      Paint()..color = const Color(0xFF94A3B8),
    );
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.5;
    for (var x = 0.0; x < w; x += 28) {
      canvas.drawLine(Offset(x, roadY + h * 0.06), Offset(x + 14, roadY + h * 0.06), dash);
    }

    _drawWaterPlant(canvas, Offset(w * 0.08, h * 0.28), w * 0.38, h * 0.38);
    _drawDeliveryVan(canvas, Offset(w * 0.52, roadY - h * 0.14), w * 0.42, h * 0.18);

  // Water cans beside van
    _drawWaterCan(canvas, Offset(w * 0.88, roadY - h * 0.08), 22, false);
    _drawWaterCan(canvas, Offset(w * 0.82, roadY - h * 0.06), 18, true);
    _drawWaterCan(canvas, Offset(w * 0.76, roadY - h * 0.04), 16, false);

    // Foreground waves
    _drawWaves(canvas, w, h, 0.88, const Color(0xFF38BDF8), 0.35);
    _drawWaves(canvas, w, h, 0.94, const Color(0xFF0EA5E9), 0.55);
  }

  void _drawWaterPlant(Canvas canvas, Offset origin, double pw, double ph) {
    final building = Paint()..color = const Color(0xFF1E3A8A);
    final tank = Paint()..color = const Color(0xFF60A5FA);
    final roof = Paint()..color = const Color(0xFF0F172A);

    // Main building
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy + ph * 0.35, pw * 0.7, ph * 0.55),
        const Radius.circular(6),
      ),
      building,
    );
    // Roof
    final roofPath = Path()
      ..moveTo(origin.dx - 4, origin.dy + ph * 0.35)
      ..lineTo(origin.dx + pw * 0.35, origin.dy + ph * 0.12)
      ..lineTo(origin.dx + pw * 0.74, origin.dy + ph * 0.35)
      ..close();
    canvas.drawPath(roofPath, roof);

    // RO tank cylinder
    final tankRect = Rect.fromLTWH(
      origin.dx + pw * 0.55,
      origin.dy + ph * 0.08,
      pw * 0.35,
      ph * 0.45,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tankRect, const Radius.circular(12)),
      tank,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tankRect.deflate(4), const Radius.circular(10)),
      Paint()..color = const Color(0xFF93C5FD),
    );
    // Tank cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(tankRect.left + 8, tankRect.top - 8, tankRect.width - 16, 12),
        const Radius.circular(4),
      ),
      roof,
    );

    // Windows
    final window = Paint()..color = const Color(0xFFBAE6FD);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              origin.dx + 12 + col * 28,
              origin.dy + ph * 0.42 + row * 22,
              18,
              14,
            ),
            const Radius.circular(3),
          ),
          window,
        );
      }
    }

    // Sign board
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + 4, origin.dy + ph * 0.52, pw * 0.45, 14),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF2563EB),
    );
  }

  void _drawDeliveryVan(Canvas canvas, Offset origin, double vw, double vh) {
    final body = Paint()..color = const Color(0xFF1D4ED8);
    final cabin = Paint()..color = const Color(0xFF1E40AF);
    final wheel = Paint()..color = const Color(0xFF0F172A);

    // Van body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy + vh * 0.25, vw * 0.72, vh * 0.55),
        const Radius.circular(8),
      ),
      body,
    );
    // Cabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + vw * 0.58, origin.dy + vh * 0.15, vw * 0.38, vh * 0.5),
        const Radius.circular(6),
      ),
      cabin,
    );
    // Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx + vw * 0.62, origin.dy + vh * 0.22, vw * 0.28, vh * 0.22),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFBAE6FD),
    );
    // Wheels
    canvas.drawCircle(Offset(origin.dx + vw * 0.22, origin.dy + vh * 0.82), vh * 0.12, wheel);
    canvas.drawCircle(Offset(origin.dx + vw * 0.78, origin.dy + vh * 0.82), vh * 0.12, wheel);
    canvas.drawCircle(Offset(origin.dx + vw * 0.22, origin.dy + vh * 0.82), vh * 0.06,
        Paint()..color = const Color(0xFF94A3B8));
    canvas.drawCircle(Offset(origin.dx + vw * 0.78, origin.dy + vh * 0.82), vh * 0.06,
        Paint()..color = const Color(0xFF94A3B8));

    // Cans loaded on van
    _drawWaterCan(canvas, Offset(origin.dx + vw * 0.12, origin.dy + vh * 0.05), 14, false);
    _drawWaterCan(canvas, Offset(origin.dx + vw * 0.28, origin.dy + vh * 0.02), 14, true);
    _drawWaterCan(canvas, Offset(origin.dx + vw * 0.44, origin.dy + vh * 0.05), 14, false);
  }

  void _drawWaterCan(Canvas canvas, Offset c, double radius, bool cool) {
    final body = Paint()
      ..color = cool ? const Color(0xFF0EA5E9) : const Color(0xFF22C55E);
    final cap = Paint()..color = const Color(0xFF64748B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: radius * 1.1, height: radius * 1.6),
        Radius.circular(radius * 0.25),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - radius * 0.75),
          width: radius * 0.9,
          height: radius * 0.35,
        ),
        Radius.circular(radius * 0.12),
      ),
      cap,
    );
    if (cool) {
      canvas.drawCircle(
        c,
        radius * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  void _drawWaves(Canvas canvas, double w, double h, double yFactor, Color color, double alpha) {
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, h * yFactor);
    for (var x = 0.0; x <= w; x += 4) {
      final y = h * yFactor + math.sin((x / w) * math.pi * 4) * 6;
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, paint);
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
                  child: Icon(Icons.water_drop, size: 13, color: LoginColors.brandBlue),
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
              'Admin: admin@srisai.com / admin123\nDriver: driver@srisai.com / driver123',
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
        backgroundColor: isWelcome ? const Color(0xFFF6FAFE) : LoginColors.pageBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            LoginPremiumBackground(variant: backgroundVariant),
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
        Positioned(
          top: 4,
          child: LoginLogoBadge(),
        ),
      ],
    );
  }
}
