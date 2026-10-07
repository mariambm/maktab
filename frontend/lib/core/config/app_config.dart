/// Build-time configuration. Override with `--dart-define=API_BASE_URL=https://...`.
abstract final class AppConfig {
  /// Android emulators reach the host machine at 10.0.2.2; iOS simulators and web use localhost.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
