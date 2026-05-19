import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/services/shop_map_launcher.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

/// Your water shop (admin) — shown on contract customer account page.
class CustomerShopInfoCard extends StatelessWidget {
  const CustomerShopInfoCard({
    super.key,
    required this.settings,
  });

  final BusinessSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CustomerColors.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CustomerColors.accent.withValues(alpha: 0.15),
                      CustomerColors.accent.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: CustomerColors.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your water shop',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CustomerColors.labelGrey,
                      ),
                    ),
                    Text(
                      settings.businessName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.titleNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: settings.address,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: settings.phone,
            onTap: () {
              Clipboard.setData(ClipboardData(text: settings.phone));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Phone copied', style: GoogleFonts.poppins()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          if (settings.email.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: settings.email,
            ),
          ],
          if (settings.hasMapPin) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ShopMapLauncher.directions(
                  address: settings.address,
                  latitude: settings.shopLatitude,
                  longitude: settings.shopLongitude,
                ),
                icon: const Icon(Icons.directions_rounded, size: 18),
                label: Text(
                  'Directions to shop',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CustomerColors.accent,
                  side: BorderSide(color: CustomerColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CustomerColors.labelGrey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CustomerColors.labelGrey,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CustomerColors.titleNavy,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.copy_rounded, size: 16, color: CustomerColors.accent),
        ],
      ),
    );
  }
}
