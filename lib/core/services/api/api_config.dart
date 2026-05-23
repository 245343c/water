import 'package:flutter/foundation.dart';

/// Set to true to use the MongoDB backend instead of in-memory mock data.
const bool useBackend = true;

/// Local backend base URL.
/// - Windows / macOS / Linux / iOS simulator / Web: `localhost`
/// - Android emulator: `10.0.2.2` (maps to host machine)
String get backendBaseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000/api';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}
