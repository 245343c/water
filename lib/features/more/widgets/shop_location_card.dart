import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:sri_sai_ro_water/core/services/shop_location_service.dart';
import 'package:sri_sai_ro_water/core/services/shop_map_launcher.dart';
import 'package:sri_sai_ro_water/core/widgets/shop_map_preview.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';

class ShopLocationCard extends StatelessWidget {
  const ShopLocationCard({
    super.key,
    required this.settings,
    this.onEditLocation,
  });

  final BusinessSettings settings;
  final VoidCallback? onEditLocation;

  @override
  Widget build(BuildContext context) {
    final hasPin = settings.hasMapPin;
    final center = hasPin
        ? LatLng(settings.shopLatitude!, settings.shopLongitude!)
        : ShopLocationService.defaultCenter;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ShopMapPreview(
                center: center,
                zoom: hasPin ? 16 : 13,
                showMarker: hasPin,
                interactive: true,
                height: 168,
              ),
              if (!hasPin)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.72),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_location_alt_outlined,
                            size: 36,
                            color: MoreColors.iconNavy.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No pin set — tap Edit to add',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: MoreColors.labelGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.store_rounded, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        'Shop location',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: MoreColors.titleNavy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        settings.address,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.4,
                          color: MoreColors.labelGrey,
                        ),
                      ),
                    ),
                    if (onEditLocation != null)
                      TextButton(
                        onPressed: onEditLocation,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Edit pin',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: MoreColors.iconNavy,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MapActionButton(
                        label: 'Open in Maps',
                        icon: Icons.map_rounded,
                        filled: true,
                        onTap: () => ShopMapLauncher.open(
                          address: settings.address,
                          latitude: settings.shopLatitude,
                          longitude: settings.shopLongitude,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MapActionButton(
                        label: 'Directions',
                        icon: Icons.directions_rounded,
                        filled: false,
                        onTap: () => ShopMapLauncher.directions(
                          address: settings.address,
                          latitude: settings.shopLatitude,
                          longitude: settings.shopLongitude,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? const Color(0xFF1A73E8) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: const Color(0xFFBFDBFE)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Colors.white : const Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : const Color(0xFF2563EB),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
