import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared premium layout primitives for mobile, tablet, and desktop.
class PremiumResponsiveBody extends StatelessWidget {
  const PremiumResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 920,
    this.alignment = Alignment.topCenter,
    this.horizontalPadding = 12,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final sidePadding = screenWidth >= 1200
            ? horizontalPadding + 8
            : horizontalPadding;
        final availableWidth = constraints.hasBoundedWidth
            ? math.max(0, constraints.maxWidth - (sidePadding * 2))
            : screenWidth;
        // Keep full-width feeling on common laptop screens, and constrain only
        // on extra-wide layouts for readability.
        final shouldUseFullWidth =
            maxWidth >= 1180 && availableWidth <= 1536;
        final effectiveMaxWidth = shouldUseFullWidth ? availableWidth : maxWidth;
        final width = math.min(availableWidth, effectiveMaxWidth).toDouble();

        final sizedChild = constraints.hasBoundedHeight
            ? SizedBox(
                width: width,
                height: constraints.maxHeight,
                child: child,
              )
            : SizedBox(
                width: width,
                child: child,
              );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: Align(
            alignment: alignment,
            child: sizedChild,
          ),
        );
      },
    );
  }
}

class PremiumStatusBadge extends StatelessWidget {
  const PremiumStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
