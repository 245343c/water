import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// GPS + address lookup for shop map pin (no manual lat/long for admin).
abstract final class ShopLocationService {
  static const LatLng defaultCenter = LatLng(16.9902, 81.7780);

  static Future<bool> ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<LatLng> getCurrentPosition() async {
    final allowed = await ensureLocationPermission();
    if (!allowed) {
      throw const ShopLocationException(
        'Location permission denied. Enable GPS in device settings.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    return LatLng(position.latitude, position.longitude);
  }

  static Future<LatLng> coordinatesFromAddress(String address) async {
    final query = address.trim();
    if (query.isEmpty) {
      throw const ShopLocationException('Enter your shop address first.');
    }
    final results = await locationFromAddress(query);
    if (results.isEmpty) {
      throw const ShopLocationException(
        'Could not find that address on the map. Try tap on map or use GPS.',
      );
    }
    final loc = results.first;
    return LatLng(loc.latitude, loc.longitude);
  }

  static Future<String> labelForCoordinates(LatLng point) async {
    try {
      final marks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (marks.isEmpty) return _formatCoords(point);
      return _formatPlacemark(marks.first);
    } catch (_) {
      return _formatCoords(point);
    }
  }

  static String _formatCoords(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

  static String _formatPlacemark(Placemark p) {
    final parts = <String>[
      if (p.street != null && p.street!.trim().isNotEmpty) p.street!,
      if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) p.subLocality!,
      if (p.locality != null && p.locality!.trim().isNotEmpty) p.locality!,
      if (p.administrativeArea != null && p.administrativeArea!.trim().isNotEmpty)
        p.administrativeArea!,
    ];
    if (parts.isEmpty) {
      return [p.name, p.country].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    }
    return parts.join(', ');
  }
}

class ShopLocationException implements Exception {
  const ShopLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
