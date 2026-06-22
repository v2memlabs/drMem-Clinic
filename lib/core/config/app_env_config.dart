/// Uygulama ortamı — maintenance ve telemetry ayrımı.
abstract final class AppEnvConfig {
  static AppEnvironment environment = AppEnvironment.production;

  static void loadFromEnvironment() {
    environment = _parse(
      const String.fromEnvironment('APP_ENV', defaultValue: 'production'),
    );
  }

  static void applyOverrides(Map<String, dynamic> raw) {
    final env = _stringValue(raw['APP_ENV']);
    if (env != null) {
      environment = _parse(env);
    }
  }

  static String? _stringValue(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool get isProduction => environment == AppEnvironment.production;

  static bool get isStaging => environment == AppEnvironment.staging;

  static bool get isDev => environment == AppEnvironment.dev;

  static bool get isNonProduction => !isProduction;

  static AppEnvironment _parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'production':
      case 'prod':
      default:
        return AppEnvironment.production;
    }
  }
}

enum AppEnvironment {
  dev,
  staging,
  production,
}
