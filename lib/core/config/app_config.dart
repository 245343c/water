/// App-wide toggles. Flip when wiring Firebase for instant delivery.
abstract final class AppConfig {
  /// Instant / walk-in jobs: memory + local notifications only (no cloud functions).
  static const bool useInstantDispatchMock = true;

  /// Demo driver id — link auth account to this id in admin Drivers screen.
  static const String mockDriverId = 'mock-driver-1';
}
