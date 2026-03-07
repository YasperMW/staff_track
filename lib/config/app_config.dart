enum AppEnvironment {
  dev,
  prod,
}

class AppConfig {
  /// Change this value when building for different environments.
  static const AppEnvironment environment = AppEnvironment.dev;

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return 'http://192.168.1.179:8888';
      case AppEnvironment.prod:
        return 'https://staff-track-api.onrender.com';
    }
  }
}
