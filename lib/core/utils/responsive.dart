import 'package:flutter/material.dart';

abstract final class Responsive {
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 900;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return 720;
    if (width >= tabletBreakpoint) return 640;
    return width;
  }
}
