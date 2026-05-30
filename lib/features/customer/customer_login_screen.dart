import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/repositories/auth_repository.dart';
import 'package:sri_sai_ro_water/data/repositories/water_plant_repository.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';
import 'package:sri_sai_ro_water/routing/app_router.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      _snack('Enter a valid 10-digit mobile number');
      return;
    }

    setState(() => _loading = true);
    final error = await context.read<AuthRepository>().requestCustomerOtp(phone);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _otpSent = error == null;
    });

    if (error != null) {
      _snack(error);
      return;
    }
    _snack('OTP sent. Check your mobile.');
  }

  Future<void> _verify() async {
    final auth = context.read<AuthRepository>();
    final repo = context.read<WaterPlantRepository>();

    setState(() => _loading = true);
    String? error;
    try {
      error = await auth.verifyCustomerOtp(
        phone: _phoneController.text,
        otp: _otpController.text,
      );
    } on FirebaseException catch (e) {
      error = 'OTP sign-in failed: ${e.message ?? e.code}';
    } catch (_) {
      error = 'OTP sign-in failed. Please try again';
    }

    setState(() => _loading = false);
    if (!mounted) return;
    if (error != null) {
      _snack(error);
      return;
    }

    final user = auth.currentUser!;
    setState(() => _loading = true);
    try {
      await repo.linkContractCustomerOnLoginFromFirestore(
        userId: user.id,
        phone: user.phone,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Customer link failed: ${e.message ?? e.code}');
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Customer link failed. Please try again');
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);

    final isContract = repo.isMonthlyContractAppUser(
      user.id,
      phone: user.phone,
    );
    final crm = repo.linkedCrmCustomerForAppUser(user.id);
    if (crm == null) {
      await auth.logout();
      _snack('This mobile number is not added by a water plant admin.');
      return;
    }

    auth.markCustomerOnboardingComplete(user.id, name: crm.name);

    final profile = repo.customerProfileByUserId(user.id);
    final currentUser = auth.currentUser ?? user;
    final needsOnboarding =
        !isContract &&
        (!currentUser.customerProfileComplete ||
            profile == null ||
            !profile.onboardingComplete);
    context.go(
      needsOnboarding ? AppRoutes.customerOnboarding : AppRoutes.customerHome,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          SizedBox.expand(
            child: CustomPaint(painter: _CustomerLoginBgPainter()),
          ),
          SafeArea(
            child: PremiumResponsiveBody(
              maxWidth: 560,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => context.canPop()
                                    ? context.pop()
                                    : context.go(AppRoutes.welcome),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.water_drop_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Order\npure water',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      height: 1.08,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Home delivery - Fresh RO water - Fast and reliable',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                26,
                                24,
                                30,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(32),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, -8),
                                  ),
                                ],
                              ),
                              child: _LoginCard(
                                otpSent: _otpSent,
                                loading: _loading,
                                phoneController: _phoneController,
                                otpController: _otpController,
                                onSendOtp: _sendOtp,
                                onVerify: _verify,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.otpSent,
    required this.loading,
    required this.phoneController,
    required this.otpController,
    required this.onSendOtp,
    required this.onVerify,
  });

  final bool otpSent;
  final bool loading;
  final TextEditingController phoneController;
  final TextEditingController otpController;
  final VoidCallback onSendOtp;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sign in',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: CustomerColors.titleNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter your mobile number to receive OTP',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: CustomerColors.labelGrey,
          ),
        ),
        const SizedBox(height: 20),
        CustomerTextField(
          label: 'Mobile number',
          controller: phoneController,
          hint: '9876543210',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        if (otpSent) ...[
          const SizedBox(height: 12),
          CustomerTextField(
            label: 'OTP code',
            controller: otpController,
            hint: '6-digit code',
            icon: Icons.sms_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: 20),
        CustomerPrimaryButton(
          label: otpSent ? 'Verify & continue' : 'Send OTP',
          loading: loading,
          icon: otpSent ? Icons.verified_rounded : Icons.send_rounded,
          onPressed: otpSent ? onVerify : onSendOtp,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            'Use the mobile number added by your water plant admin.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: CustomerColors.labelGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _CustomerLoginBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        stops: [0, 0.55, 1],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final rnd = math.Random(42);
    for (var i = 0; i < 35; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * h * 0.45;
      final r = rnd.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    final orbPaint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(w * 0.9, h * 0.1), w * 0.35, orbPaint);
    canvas.drawCircle(Offset(w * 0.05, h * 0.22), w * 0.22, orbPaint);

    _drawWave(canvas, w, h, 0.75, 0.09, const Color(0xFF1E40AF));
    _drawWave(canvas, w, h, 0.82, 0.07, const Color(0xFF1D4ED8));

    _drawCan(canvas, Offset(w * 0.15, h * 0.52), 26, const Color(0xFF60A5FA));
    _drawCan(canvas, Offset(w * 0.28, h * 0.48), 20, const Color(0xFF93C5FD));
    _drawCan(canvas, Offset(w * 0.78, h * 0.50), 28, const Color(0xFF3B82F6));
    _drawCan(canvas, Offset(w * 0.90, h * 0.46), 18, const Color(0xFF60A5FA));
    _drawVan(canvas, Offset(w * 0.35, h * 0.60), w * 0.32);
  }

  void _drawWave(
    Canvas canvas,
    double w,
    double h,
    double yFrac,
    double amp,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final path = Path()..moveTo(0, h * yFrac);
    for (var x = 0.0; x <= w; x += 3) {
      final y = h * yFrac + math.sin((x / w) * math.pi * 4) * (h * amp);
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCan(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()..color = color.withValues(alpha: 0.35);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: r, height: r * 2.2),
      Radius.circular(r * 0.3),
    );
    canvas.drawRRect(body, paint);

    final hi = Paint()..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - r * 0.2, center.dy - r * 0.3),
          width: r * 0.25,
          height: r,
        ),
        Radius.circular(r * 0.12),
      ),
      hi,
    );
  }

  void _drawVan(Canvas canvas, Offset origin, double w) {
    final h = w * 0.5;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, w, h * 0.65),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, paint);

    final cabin = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        origin.dx + w * 0.62,
        origin.dy - h * 0.3,
        w * 0.38,
        h * 0.62,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(cabin, paint);

    final wheel = Paint()..color = Colors.white.withValues(alpha: 0.25);
    canvas.drawCircle(
      Offset(origin.dx + w * 0.2, origin.dy + h * 0.65),
      h * 0.18,
      wheel,
    );
    canvas.drawCircle(
      Offset(origin.dx + w * 0.78, origin.dy + h * 0.65),
      h * 0.18,
      wheel,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
