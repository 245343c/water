/// App-wide production toggles.
abstract final class AppConfig {
  /// Keep false in production so instant / walk-in jobs use Firebase Functions.
  static const bool useInstantDispatchMock = false;

  /// Demo driver id — link auth account to this id in admin Drivers screen.
  static const String mockDriverId = 'mock-driver-1';
}
