import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:sri_sai_ro_water/core/services/shop_map_launcher.dart';
import 'package:sri_sai_ro_water/data/models/business_settings.dart';
import 'package:sri_sai_ro_water/features/more/widgets/more_screen_widgets.dart';

/// Shop map preview + open in Google Maps (admin reference / share with customers).
class ShopLocationCard extends StatelessWidget {
  const ShopLocationCard({super.key, required this.settings});

  final BusinessSettings settings;

  @override
  Widget build(BuildContext context) {
    final hasPin = settings.hasMapPin;
    final lat = settings.shopLatitude ?? 16.9902;
    final lng = settings.shopLongitude ?? 81.7780;
    final point = LatLng(lat, lng);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                if (hasPin)
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: point,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.srisai.rowater',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: point,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFDC2626),
                              size: 44,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Container(
                    color: const Color(0xFFEFF6FF),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: MoreColors.titleNavy.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add map pin in Settings',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: MoreColors.labelGrey,
                            ),
                          ),
                        ],
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.address,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.4,
                    color: MoreColors.labelGrey,
                  ),
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
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
