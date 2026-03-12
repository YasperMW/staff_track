enum AppEnvironment {
  dev1,
  dev2,
  prod,
}

class AppConfig {
  /// Change this value when building for different environments.
  static const AppEnvironment environment = AppEnvironment.prod;

  static String get apiBaseUrl {
    switch (environment) {
      case AppEnvironment.dev1:
        return 'http://192.168.100.199:8888';
      case AppEnvironment.dev2:
        return 'http://192.168.100.199:8888';
      case AppEnvironment.prod:
        return 'https://staff-track-api.onrender.com';
    }
  }
}
