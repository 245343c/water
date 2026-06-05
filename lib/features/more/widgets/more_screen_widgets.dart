import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/theme/app_colors.dart';
import 'package:sri_sai_ro_water/core/widgets/admin_tab_header.dart';
import 'package:sri_sai_ro_water/core/widgets/premium_responsive.dart';
import 'package:sri_sai_ro_water/core/widgets/home_delivery_choice.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/customers_screen_widgets.dart';

abstract final class MoreColors {
  static const Color screenBg = AppColors.surface;
  static const Color titleNavy = AppColors.textPrimary;
  static const Color labelGrey = Color(0xFF6B7280);
  static const Color cardBorder = AppColors.cardBorder;
  static const Color iconTileBg = Color(0xFFEFF6FF);
  static const Color iconNavy = Color(0xFF1E3A8A);
  static const Color divider = Color(0xFFE5E7EB);
}

class MoreScaffold extends StatelessWidget {
  const MoreScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: CustomersColors.screenGradient,
        child: PremiumResponsiveBody(
          maxWidth: 1180,
          horizontalPadding: 4,
          child: child,
        ),
      ),
    );
  }
}

class MoreHeader extends StatelessWidget {
  const MoreHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AdminTabPageHeader(
      title: title,
      icon: Icons.account_circle_rounded,
      iconColor: const Color(0xFF38BDF8),
    );
  }
}

class MoreBusinessProfileCard extends StatelessWidget {
  const MoreBusinessProfileCard({
    super.key,
    required this.settings,
    required this.onTap,
  });

  final BusinessSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: CustomersColors.whiteCard,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          CustomersColors.headerTop,
                          CustomersColors.headerBottom,
                        ],
                      ),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  CustomersColors.addButton.withValues(
                                    alpha: 0.15,
                                  ),
                                  MoreColors.iconNavy.withValues(alpha: 0.08),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              color: CustomersColors.addButton,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.businessName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: MoreColors.titleNavy,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap Edit to update shop details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: MoreColors.iconNavy,
                                  ),
                                ),
                                if (settings.address.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _ProfileLine(
                                    icon: Icons.location_on_outlined,
                                    text: settings.address,
                                    maxLines: 2,
                                  ),
                                ],
                                const SizedBox(height: 6),
                                _ProfileLine(
                                  icon: Icons.phone_outlined,
                                  text: settings.phone,
                                ),
                                if (settings.email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  _ProfileLine(
                                    icon: Icons.email_outlined,
                                    text: settings.email,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _StatusChip(
                                      icon: settings.homeDeliveryAvailable
                                          ? Icons.delivery_dining_rounded
                                          : Icons.storefront_outlined,
                                      label: settings.homeDeliveryAvailable
                                          ? 'Home delivery on'
                                          : 'Pickup only',
                                      color: settings.homeDeliveryAvailable
                                          ? const Color(0xFF059669)
                                          : MoreColors.labelGrey,
                                      bg: settings.homeDeliveryAvailable
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFF3F4F6),
                                    ),
                                    _StatusChip(
                                      icon: settings.hasMapPin
                                          ? Icons.place_rounded
                                          : Icons.place_outlined,
                                      label: settings.hasMapPin
                                          ? 'Map pin set'
                                          : 'No map pin',
                                      color: settings.hasMapPin
                                          ? CustomersColors.addButton
                                          : MoreColors.labelGrey,
                                      bg: settings.hasMapPin
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF3F4F6),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: Colors.white,
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
            ),
          ),
        ),
      ),
    );
  }
}

/// Home delivery toggle — same tiles as settings, no descriptions.
class MoreHomeDeliveryCard extends StatelessWidget {
  const MoreHomeDeliveryCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: CustomersColors.whiteCard,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: HomeDeliveryChoice(
              value: value,
              onChanged: onChanged,
              hideDescriptions: true,
              titleOnly: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Drivers + sign out — routes live under Customers → Route filter.
class MoreManagementCard extends StatelessWidget {
  const MoreManagementCard({
    super.key,
    required this.onDrivers,
    required this.onSignOut,
  });

  final VoidCallback onDrivers;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: CustomersColors.whiteCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Staff & account',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: MoreColors.titleNavy,
                ),
              ),
            ),
            _AccountRow(
              icon: Icons.local_shipping_rounded,
              iconBg: MoreColors.iconTileBg,
              iconColor: MoreColors.iconNavy,
              title: 'Drivers',
              subtitle: 'Delivery staff logins',
              onTap: onDrivers,
            ),
            const Divider(height: 1, indent: 68, color: MoreColors.divider),
            _AccountRow(
              icon: Icons.logout_rounded,
              iconBg: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFDC2626),
              title: 'Sign out',
              subtitle: 'Log out of admin account',
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: MoreColors.titleNavy,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: MoreColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: MoreColors.labelGrey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: MoreColors.labelGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.35,
              color: MoreColors.labelGrey,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class MoreMenuTile extends StatelessWidget {
  const MoreMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: CustomersColors.whiteCard,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: MoreColors.iconTileBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: MoreColors.iconNavy, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: MoreColors.titleNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: MoreColors.labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showChevron)
                    const Icon(
                      Icons.chevron_right,
                      color: MoreColors.labelGrey,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MoreSectionTitle extends StatelessWidget {
  const MoreSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: MoreColors.titleNavy,
        ),
      ),
    );
  }
}

class MoreSectionDivider extends StatelessWidget {
  const MoreSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Divider(height: 1, thickness: 1, color: MoreColors.divider),
    );
  }
}

class MoreVersionLabel extends StatelessWidget {
  const MoreVersionLabel({super.key, this.version = '1.0.0'});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: Text(
        'Version $version',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 13, color: MoreColors.labelGrey),
      ),
    );
  }
}

