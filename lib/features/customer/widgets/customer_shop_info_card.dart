import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sri_sai_ro_water/core/services/shop_map_launcher.dart';
import 'package:sri_sai_ro_water/core/utils/currency_utils.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/data/models/shop.dart';
import 'package:sri_sai_ro_water/features/customer/widgets/customer_theme.dart';

/// Admin / registered shop on bulk customer Account tab.
class CustomerAccountShopCard extends StatelessWidget {
  const CustomerAccountShopCard({
    super.key,
    required this.settings,
    this.shop,
    this.onOrder,
  });

  final BusinessSettings settings;
  final Shop? shop;
  final VoidCallback? onOrder;

  @override
  Widget build(BuildContext context) {
    final canOrder = shop != null && shop!.isVisibleToCustomers && onOrder != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomerColors.accent.withValues(alpha: 0.08),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerColors.accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: CustomerColors.accent.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CustomerColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: CustomerColors.accent,
                  size: 28,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: CustomerColors.titleNavy,
                      ),
                    ),
                    Text(
                      'Monthly billing & deliveries',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: CustomerColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: settings.address),
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
          if (shop != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _PriceChip(
                  label: 'Normal',
                  price: CurrencyUtils.format(shop!.normalPrice),
                ),
                const SizedBox(width: 8),
                _PriceChip(
                  label: 'Cool',
                  price: CurrencyUtils.format(shop!.coolPrice),
                  cool: true,
                ),
              ],
            ),
          ],
          if (settings.hasMapPin) ...[
            const SizedBox(height: 12),
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
                  'Directions',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CustomerColors.accent,
                  side: const BorderSide(color: CustomerColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          if (canOrder) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOrder,
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text(
                  'Order from this shop',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: CustomerColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.price, this.cool = false});

  final String label;
  final String price;
  final bool cool;

  @override
  Widget build(BuildContext context) {
    final color = cool ? const Color(0xFF0EA5E9) : CustomerColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $price',
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Your water shop (admin) — legacy alias.
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
