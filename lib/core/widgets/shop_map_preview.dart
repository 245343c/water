import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

/// Reusable OSM map preview — fixes blank map via onMapReady + correct user agent.
class ShopMapPreview extends StatefulWidget {
  const ShopMapPreview({
    super.key,
    required this.center,
    this.zoom = 15,
    this.interactive = true,
    this.showMarker = true,
    this.height = 160,
  });

  final LatLng center;
  final double zoom;
  final bool interactive;
  final bool showMarker;
  final double height;

  static const String _userAgent = 'com.srisai.rowater.sri_sai_ro_water';

  @override
  State<ShopMapPreview> createState() => _ShopMapPreviewState();
}

class _ShopMapPreviewState extends State<ShopMapPreview> {
  final _controller = MapController();
  bool _ready = false;
  String? _tileError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ShopMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center && _ready) {
      _controller.move(widget.center, widget.zoom);
    }
  }

  void _onMapReady() {
    _controller.move(widget.center, widget.zoom);
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: widget.zoom,
              onMapReady: _onMapReady,
              interactionOptions: InteractionOptions(
                flags: widget.interactive
                    ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
                    : InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: ShopMapPreview._userAgent,
                errorTileCallback: (_, error, stack) {
                  if (_tileError == null && mounted) {
                    setState(() => _tileError = error.toString());
                  }
                },
              ),
              if (widget.showMarker)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.center,
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
          ),
          if (!_ready)
            Container(
              color: const Color(0xFFEFF6FF),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (_tileError != null && _ready)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Map tiles need internet connection',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 10, color: Color(0xFF6B7280)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
