import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/data/models/delivery_route.dart';

/// Driver persona theme — teal field-app accent (see PRODUCT_ARCHITECTURE.md).
abstract final class DriverColors {
  static const Color screenBg = Color(0xFFF0FDFA);

  /// Flat background for lists and detail body — no gradient bleed.
  static const Color contentBg = Color(0xFFF3F4F6);
  static const Color headerStart = Color(0xFF0F766E);
  static const Color headerEnd = Color(0xFF14B8A6);
  static const Color accent = Color(0xFF0D9488);
  static const Color accentBright = Color(0xFF2DD4BF);
  static const Color titleNavy = Color(0xFF111827);
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);

  static BoxDecoration get headerGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [headerStart, headerEnd],
        ),
      );

  /// Page chrome — teal header fading to field background (matches admin layout).
  static BoxDecoration get screenGradient => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.38, 1],
          colors: [headerStart, headerEnd, screenBg],
        ),
      );

  static BoxDecoration get whiteCard => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

class DriverScaffold extends StatelessWidget {
  const DriverScaffold({super.key, required this.child, this.usePageGradient = false});

  final Widget child;
  final bool usePageGradient;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: usePageGradient ? DriverColors.screenGradient : null,
        color: usePageGradient ? null : DriverColors.screenBg,
        child: PremiumResponsiveBody(
          maxWidth: 1180,
          horizontalPadding: usePageGradient ? 4 : 0,
          child: child,
        ),
      ),
    );
  }
}

class DriverHeader extends StatelessWidget {
  const DriverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: DriverColors.headerGradient,
      padding: EdgeInsets.fromLTRB(
        onBack != null ? 4 : 20,
        MediaQuery.paddingOf(context).top + 8,
        20,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: onBack != null ? 4 : 6),
            Padding(
              padding: EdgeInsets.only(left: onBack != null ? 40 : 0),
              child: Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DriverHeroStats extends StatelessWidget {
  const DriverHeroStats({
    super.key,
    required this.deliveriesToday,
    required this.cansToday,
    required this.pendingOrders,
    this.pendingLabel = 'Orders',
  });

  final int deliveriesToday;
  final int cansToday;
  final int pendingOrders;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DriverColors.headerStart, DriverColors.headerEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: DriverColors.accent.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _Stat(label: 'Deliveries', value: '$deliveriesToday'),
          _divider(),
          _Stat(label: 'Cans today', value: '$cansToday'),
          _divider(),
          _Stat(label: pendingLabel, value: '$pendingOrders'),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.25),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverSectionTitle extends StatelessWidget {
  const DriverSectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DriverColors.titleNavy,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

const String driverUnassignedRouteFilter = '__driver_unassigned_route__';

class DriverRouteFilter extends StatelessWidget {
  const DriverRouteFilter({
    super.key,
    required this.routes,
    required this.selected,
    required this.onSelected,
    this.showUnassigned = false,
  });

  final List<DeliveryRoute> routes;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool showUnassigned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: DropdownButtonFormField<String?>(
        value: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Route',
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: DriverColors.labelGrey,
          ),
          prefixIcon: const Icon(
            Icons.route_rounded,
            color: DriverColors.accent,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: DriverColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: DriverColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: DriverColors.accent,
              width: 1.4,
            ),
          ),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text('All Routes', style: GoogleFonts.poppins()),
          ),
          if (showUnassigned)
            DropdownMenuItem<String?>(
              value: driverUnassignedRouteFilter,
              child: Text('Unassigned', style: GoogleFonts.poppins()),
            ),
          for (final route in routes)
            DropdownMenuItem<String?>(
              value: route.id,
              child: Text(route.name, style: GoogleFonts.poppins()),
            ),
        ],
        onChanged: onSelected,
      ),
    );
  }
}

class DriverPrimaryButton extends StatelessWidget {
  const DriverPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.local_shipping_rounded,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DriverColors.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
