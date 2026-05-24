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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: _locationCardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showLocationMap(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: MoreColors.iconNavy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: MoreColors.iconNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: MoreColors.titleNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasPin ? 'View shop map and directions' : 'Add shop pin for directions',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: MoreColors.labelGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: MoreColors.labelGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationMap(BuildContext context) {
    final hasPin = settings.hasMapPin;
    final center = hasPin
        ? LatLng(settings.shopLatitude!, settings.shopLongitude!)
        : ShopLocationService.defaultCenter;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.paddingOf(ctx).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Shop location',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: MoreColors.titleNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.address,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    height: 1.4,
                    color: MoreColors.labelGrey,
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ShopMapPreview(
                    center: center,
                    zoom: hasPin ? 16 : 13,
                    showMarker: hasPin,
                    interactive: true,
                    height: 220,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MapActionButton(
                        label: 'Open Maps',
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
                if (onEditLocation != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onEditLocation!();
                    },
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('Edit location pin'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _locationCardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: MoreColors.cardBorder),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ],
);

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
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : const Color(0xFF2563EB),
              ),
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
