import 'environment.dart';

/// Runtime configuration of the app.
abstract final class AppConfig {
  static const String appName = 'Sportico';

  static const String apiBaseUrl = Environment.apiBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const int defaultPageSize = 10;

  /// Polling interval for chat messages (no websocket on the backend).
  static const Duration chatPollInterval = Duration(seconds: 8);

  /// Polling interval for the unread notification badge.
  static const Duration unreadCountPollInterval = Duration(seconds: 60);
}
