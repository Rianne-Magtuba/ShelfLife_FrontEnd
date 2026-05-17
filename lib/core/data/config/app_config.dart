class AppConfig {
  // Reads from --dart-define at build time.
  // Never hardcoded, never commi
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://shelflife-api-1030171236919.asia-east1.run.app', // only used in local dev
  );
}