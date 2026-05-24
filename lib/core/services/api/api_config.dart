import 'package:flutter/foundation.dart';

/// Production mode: all app data comes from the MongoDB backend API.
/// Mock/offline mode has been removed — keep this `true`.
const bool useBackend = true;

/// Override at build/run time, e.g. physical device on LAN:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api`
const String _apiBaseUrlOverride = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

/// Backend API base URL (includes `/api` suffix).
///
/// Defaults:
/// - Web / desktop / iOS simulator: `http://localhost:3000/api`
/// - Android emulator: `http://10.0.2.2:3000/api` (host machine)
String get backendBaseUrl {
  final override = _apiBaseUrlOverride.trim();
  if (override.isNotEmpty) {
    return override.endsWith('/api')
        ? override
        : '${override.replaceAll(RegExp(r'/+$'), '')}/api';
  }
  if (kIsWeb) {
    return 'http://localhost:3000/api';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}
