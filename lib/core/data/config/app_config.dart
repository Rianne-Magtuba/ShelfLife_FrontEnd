class AppConfig {
  // Reads from --dart-define at build time.
  // Never hardcoded, never commi
  static const apiBaseUrl = String.fromEnvironment(
    'https://shelflife-api-1030171236919.asia-east1.run.app',
    defaultValue: 'https://shelflife-api-1030171236919.asia-east1.run.app', // only used in local dev
  );
}