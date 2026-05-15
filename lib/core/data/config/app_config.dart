class AppConfig {
  // Reads from --dart-define at build time.
  // Never hardcoded, never commi
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000', // only used in local dev
  );
}