import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class RolePickerScreen extends StatelessWidget {
  const RolePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          SizedBox.expand(child: CustomPaint(painter: _WelcomeBgPainter())),
          SafeArea(
            child: SizedBox(
              height: size.height,
              child: Column(
                children: [
                  // Hero section
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Pure water,\ndelivered home.',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Order RO water from trusted shops near you.\nFast · Fresh · Affordable',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                  // Cards
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'CONTINUE AS',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: CustomerColors.labelGrey,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoleTile(
                          icon: Icons.water_drop_rounded,
                          title: 'Order water',
                          subtitle: 'Search shops · Place order · Home delivery',
                          badge: 'Customer',
                          accent: CustomerColors.accent,
                          onTap: () => context.push(AppRoutes.customerLogin),
                        ),
                        const SizedBox(height: 12),
                        _RoleTile(
                          icon: Icons.storefront_rounded,
                          title: 'Staff login',
                          subtitle: 'Owner · Drivers · Billing & customers',
                          badge: 'Team',
                          accent: const Color(0xFF0F172A),
                          onTap: () => context.push(AppRoutes.login),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 13,
                                  color: CustomerColors.labelGrey),
                              const SizedBox(width: 5),
                              Text(
                                'Secure sign-in',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: CustomerColors.labelGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background gradient
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    // Stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h * 0.5;
      canvas.drawCircle(Offset(x, y), rnd.nextDouble() * 1.6 + 0.4, starPaint);
    }

    // Glow orbs
    final orb = Paint()..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawCircle(Offset(w * 0.85, h * 0.08), w * 0.4, orb);
    canvas.drawCircle(Offset(w * 0.1, h * 0.35), w * 0.25, orb);

    // Water plant silhouette (center-right)
    _drawPlant(canvas, Offset(w * 0.72, h * 0.38), w * 0.20);

    // Delivery van
    _drawVan(canvas, Offset(w * 0.05, h * 0.52), w * 0.38);

    // Water cans
    _drawCan(canvas, Offset(w * 0.08, h * 0.38), 20.0);
    _drawCan(canvas, Offset(w * 0.19, h * 0.35), 15.0);
    _drawCan(canvas, Offset(w * 0.88, h * 0.50), 22.0);

    // Wave
    _drawWave(canvas, w, h, 0.68, 0.08, const Color(0xFF1E40AF));
    _drawWave(canvas, w, h, 0.74, 0.05, const Color(0xFF2563EB));
  }

  void _drawCan(Canvas canvas, Offset c, double r) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: r, height: r * 2.2),
        Radius.circular(r * 0.3),
      ),
      p,
    );
  }

  void _drawVan(Canvas canvas, Offset origin, double w) {
    final h = w * 0.45;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.13);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx, origin.dy, w, h * 0.65), const Radius.circular(6)),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(
              origin.dx + w * 0.6, origin.dy - h * 0.28, w * 0.4, h * 0.60),
          const Radius.circular(5)),
      p,
    );
    final wheel = Paint()..color = Colors.white.withValues(alpha: 0.20);
    canvas.drawCircle(Offset(origin.dx + w * 0.2, origin.dy + h * 0.65), h * 0.18, wheel);
    canvas.drawCircle(Offset(origin.dx + w * 0.75, origin.dy + h * 0.65), h * 0.18, wheel);
  }

  void _drawPlant(Canvas canvas, Offset origin, double s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.10);
    // Base
    canvas.drawRect(Rect.fromCenter(center: origin.translate(0, s * 0.5), width: s * 1.4, height: s * 0.2), p);
    // Tower
    canvas.drawRect(Rect.fromCenter(center: origin, width: s * 0.4, height: s * 1.2), p);
    // Tank
    canvas.drawCircle(origin.translate(0, -s * 0.6), s * 0.38, p);
  }

  void _drawWave(Canvas canvas, double w, double h, double yFrac, double amp,
      Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, h * yFrac);
    for (var x = 0.0; x <= w; x += 3) {
      path.lineTo(x, h * yFrac + math.sin((x / w) * math.pi * 4) * (h * amp));
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CustomerColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 88,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(icon, color: accent, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badge,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CustomerColors.titleNavy,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: CustomerColors.labelGrey,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 15, color: accent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
