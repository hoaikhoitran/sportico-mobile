/// Build-time environment, injected via `--dart-define`.
///
/// Example:
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5095
/// ```
abstract final class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sportico-api-khoi.azurewebsites.net',
  );
}
