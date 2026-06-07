import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/features/driver/widgets/driver_theme.dart';

Future<void> showDriverResultFeedback(
  BuildContext context, {
  required bool success,
  required String title,
  String? message,
}) async {
  if (success) {
    HapticFeedback.mediumImpact();
    unawaited(SystemSound.play(SystemSoundType.click));
  } else {
    HapticFeedback.heavyImpact();
    unawaited(SystemSound.play(SystemSoundType.alert));
  }

  final color = success ? DriverColors.success : const Color(0xFFDC2626);
  final icon = success ? Icons.check_rounded : Icons.close_rounded;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, animation, secondaryAnimation) => Center(
      child: _AutoClosingDriverResultFeedbackCard(
        color: color,
        icon: icon,
        title: title,
        message: message,
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _AutoClosingDriverResultFeedbackCard extends StatefulWidget {
  const _AutoClosingDriverResultFeedbackCard({
    required this.color,
    required this.icon,
    required this.title,
    this.message,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? message;

  @override
  State<_AutoClosingDriverResultFeedbackCard> createState() =>
      _AutoClosingDriverResultFeedbackCardState();
}

class _AutoClosingDriverResultFeedbackCardState
    extends State<_AutoClosingDriverResultFeedbackCard> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DriverResultFeedbackCard(
      color: widget.color,
      icon: widget.icon,
      title: widget.title,
      message: widget.message,
    );
  }
}

class _DriverResultFeedbackCard extends StatelessWidget {
  const _DriverResultFeedbackCard({
    required this.color,
    required this.icon,
    required this.title,
    this.message,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 240,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.72, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: color, size: 46),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: DriverColors.titleNavy,
              ),
            ),
            if (message != null && message!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: DriverColors.labelGrey,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
