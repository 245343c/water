import 'package:url_launcher/url_launcher.dart';

/// Opens shop location in Google Maps (app or browser).
abstract final class ShopMapLauncher {
  static Future<bool> open({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final Uri uri;
    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      );
    } else if (address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address.trim())}',
      );
    } else {
      return false;
    }

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> directions({
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final Uri uri;
    if (latitude != null && longitude != null) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
    } else if (address.trim().isNotEmpty) {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address.trim())}',
      );
    } else {
      return false;
    }

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
