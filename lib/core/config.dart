abstract final class AppConfig {
  /// Base URL of the TrackTrash API. Override with `--dart-define=API_BASE_URL=...`.
  /// Android emulator: `http://10.0.2.2:5145`. Physical device: the LAN IP of the machine running the API.
  static const apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5145',
  );

  static const apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT_SECONDS',
    defaultValue: 15,
  );

  /// Initial map position (Plaza de Armas, Arequipa).
  static const defaultLatitude = -16.3989;
  static const defaultLongitude = -71.5369;
}
