import 'dart:io';

enum AppFlavor {
  development,
  production,
}

class AppConfig {
  final AppFlavor flavor;
  final String baseUrl;
  bool useMockData;

  AppConfig({
    required this.flavor,
    required this.baseUrl,
    this.useMockData = false,
  });

  static AppConfig? _current;
  static AppConfig get current {
    if (_current == null) {
      init(flavor: AppFlavor.development, useMockData: true);
    }
    return _current!;
  }
  static set current(AppConfig value) => _current = value;

  static void init({
    required AppFlavor flavor,
    bool? useMockData,
  }) {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    const String defaultBaseUrl = 'https://elshora-qa3aty2026.lovable.app/api/public/v1';

    final String selectedUrl = envUrl.isNotEmpty ? envUrl : defaultBaseUrl;

    // Production MUST reject unencrypted http URLs
    if (flavor == AppFlavor.production && selectedUrl.startsWith('http://')) {
      throw UnsupportedError('Production environment requires HTTPS URLs only.');
    }

    _current = AppConfig(
      flavor: flavor,
      baseUrl: selectedUrl,
      // Production ALWAYS uses remote repositories (useMockData = false)
      useMockData: flavor == AppFlavor.production ? false : (useMockData ?? false),
    );
  }

  bool get isDevelopment => flavor == AppFlavor.development;
  bool get isProduction => flavor == AppFlavor.production;
}
