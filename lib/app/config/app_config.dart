import 'environment.dart';

/// Runtime configuration of the app. All networking reads the base URL from
/// here — never hardcode a URL in an API/repository file.
abstract final class AppConfig {
  static const String appName = 'Sportico';

  static const String apiBaseUrl = Environment.apiBaseUrl;

  /// `local` | `production` (from `--dart-define=APP_ENV=...`).
  static const String environment = Environment.appEnv;

  static const bool isProduction = environment == 'production';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const int defaultPageSize = 10;

  /// Polling interval for chat messages (no websocket on the backend).
  static const Duration chatPollInterval = Duration(seconds: 8);
}
