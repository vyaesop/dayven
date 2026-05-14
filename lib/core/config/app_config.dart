enum BackendMode {
  demo,
  neon,
}

BackendMode _parseBackendMode(String value) {
  switch (value.toLowerCase()) {
    case 'neon':
      return BackendMode.neon;
    case 'demo':
    default:
      return BackendMode.demo;
  }
}

class AppConfig {
  const AppConfig({
    required this.backendMode,
    required this.apiBaseUrl,
    required this.apiBearerToken,
    required this.enableVerboseLogs,
  });

  final BackendMode backendMode;
  final String apiBaseUrl;
  final String apiBearerToken;
  final bool enableVerboseLogs;

  static final current = AppConfig._fromEnvironment();

  factory AppConfig._fromEnvironment() {
    return AppConfig(
      backendMode: _parseBackendMode(
        const String.fromEnvironment(
          'VP_BACKEND_MODE',
          defaultValue: 'demo',
        ),
      ),
      apiBaseUrl: const String.fromEnvironment(
        'VP_API_BASE_URL',
        defaultValue: '',
      ),
      apiBearerToken: const String.fromEnvironment(
        'VP_API_BEARER_TOKEN',
        defaultValue: '',
      ),
      enableVerboseLogs: const bool.fromEnvironment(
        'VP_ENABLE_VERBOSE_LOGS',
        defaultValue: false,
      ),
    );
  }

  bool get hasRemoteBackend =>
      backendMode == BackendMode.neon && apiBaseUrl.trim().isNotEmpty;
}
