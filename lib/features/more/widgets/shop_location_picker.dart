import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:sri_sai_ro_water/core/services/shop_location_service.dart';
import 'package:sri_sai_ro_water/features/customers/widgets/add_edit_customer_widgets.dart';

/// Shop pin: fixed at map center — pan/zoom freely, then confirm (no drifting marker).
class ShopLocationPicker extends StatefulWidget {
  const ShopLocationPicker({
    super.key,
    this.latitude,
    this.longitude,
    required this.addressText,
    required this.onChanged,
    this.minimal = false,
  });

  final double? latitude;
  final double? longitude;
  final String addressText;
  final void Function(double? lat, double? lng, String? placeLabel) onChanged;
  /// Compact map + My location / From address only (settings).
  final bool minimal;

  @override
  State<ShopLocationPicker> createState() => _ShopLocationPickerState();
}

class _ShopLocationPickerState extends State<ShopLocationPicker> {
  final _mapController = MapController();
  LatLng? _confirmedPin;
  String? _placeLabel;
  bool _busy = false;
  bool _mapReady = false;
  Timer? _geocodeDebounce;

  static const String _userAgent = 'com.srisai.rowater.sri_sai_ro_water';

  @override
  void initState() {
    super.initState();
    if (widget.latitude != null && widget.longitude != null) {
      _confirmedPin = LatLng(widget.latitude!, widget.longitude!);
    }
  }

  @override
  void didUpdateWidget(ShopLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      if (widget.latitude != null && widget.longitude != null) {
        _confirmedPin = LatLng(widget.latitude!, widget.longitude!);
        if (_mapReady) _flyTo(_confirmedPin!);
      }
    }
  }

  void _onMapReady() {
    final target = _confirmedPin ?? ShopLocationService.defaultCenter;
    _mapController.move(target, _confirmedPin != null ? 16 : 14);
    if (!_mapReady) {
      setState(() => _mapReady = true);
      if (_confirmedPin != null) {
        ShopLocationService.labelForCoordinates(_confirmedPin!).then((label) {
          if (mounted) setState(() => _placeLabel = label);
        });
      }
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _flyTo(LatLng point, {double zoom = 16}) {
    if (!_mapReady) return;
    _mapController.move(point, zoom);
  }

  Future<void> _commitMapCenter({bool notify = true}) async {
    if (!_mapReady) return;
    final center = _mapController.camera.center;
    setState(() {
      _confirmedPin = center;
      _busy = true;
    });
    final label = await ShopLocationService.labelForCoordinates(center);
    if (!mounted) return;
    setState(() {
      _placeLabel = label;
      _busy = false;
    });
    if (notify) widget.onChanged(center.latitude, center.longitude, label);
  }

  void _onMapMoved() {
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) _commitMapCenter();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _busy = true);
    try {
      final point = await ShopLocationService.getCurrentPosition();
      _flyTo(point, zoom: 17);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _commitMapCenter();
    } on ShopLocationException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Could not get GPS location. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _findFromAddress() async {
    setState(() => _busy = true);
    try {
      final point = await ShopLocationService.coordinatesFromAddress(widget.addressText);
      _flyTo(point, zoom: 16);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _commitMapCenter();
    } on ShopLocationException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Address lookup failed. Move map and confirm pin.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearPin() {
    _geocodeDebounce?.cancel();
    setState(() {
      _confirmedPin = null;
      _placeLabel = null;
    });
    widget.onChanged(null, null, null);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPin = _confirmedPin != null;
    final minimal = widget.minimal;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AddEditCustomerColors.fieldBorder),
        boxShadow: minimal
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!minimal)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AddEditCustomerColors.primaryBtn.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_location_alt_outlined,
                      color: AddEditCustomerColors.primaryBtn,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Shop on map',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AddEditCustomerColors.titleNavy,
                      ),
                    ),
                  ),
                  if (hasPin)
                    TextButton(
                      onPressed: _busy ? null : _clearPin,
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AddEditCustomerColors.labelGrey,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (hasPin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy ? null : _clearPin,
                child: Text(
                  'Clear pin',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AddEditCustomerColors.labelGrey,
                  ),
                ),
              ),
            ),
          SizedBox(
            height: minimal ? 180 : 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _confirmedPin ?? ShopLocationService.defaultCenter,
                    initialZoom: hasPin ? 16 : 14,
                    onMapReady: _onMapReady,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) _onMapMoved();
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: _userAgent,
                    ),
                  ],
                ),
                if (!_mapReady)
                  const ColoredBox(
                    color: Color(0xFFEFF6FF),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 48,
                        color: Color(0xFFDC2626),
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!minimal)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Drag map to set pin',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AddEditCustomerColors.titleNavy,
                        ),
                      ),
                    ),
                  ),
                if (_busy)
                  Container(
                    color: Colors.white.withValues(alpha: 0.55),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          if (!minimal)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy || !_mapReady ? null : () => _commitMapCenter(),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    'Confirm location',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AddEditCustomerColors.primaryBtn,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          if (minimal && hasPin && _placeLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                _placeLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AddEditCustomerColors.labelGrey,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, minimal ? 10 : 12, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    icon: Icons.my_location_rounded,
                    label: 'My location',
                    onTap: _busy ? null : _useCurrentLocation,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.search_rounded,
                    label: 'From address',
                    primary: true,
                    onTap: _busy ? null : _findFromAddress,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary ? AddEditCustomerColors.primaryBtn : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: primary ? null : Border.all(color: const Color(0xFFBFDBFE)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: primary ? Colors.white : AddEditCustomerColors.primaryBtn,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary ? Colors.white : AddEditCustomerColors.primaryBtn,
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
