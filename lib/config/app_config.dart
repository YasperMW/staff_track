enum AppEnvironment {
  dev,
  prod,
}

class AppConfig {
  /// Change this value when building for different environments.
  static const AppEnvironment environment = AppEnvironment.prod;

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.dev:
        return 'http://192.168.137.1:8888';
      case AppEnvironment.prod:
        return 'https://staff-track-api.onrender.com';
    }
  }
}
