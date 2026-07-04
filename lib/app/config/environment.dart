/// Build-time environment, injected via `--dart-define`.
///
/// | Target                        | API_BASE_URL                              |
/// |-------------------------------|-------------------------------------------|
/// | Android emulator + local API  | `http://10.0.2.2:5095` (default)          |
/// | iOS simulator + local API     | `http://127.0.0.1:5095`                   |
/// | Physical phone + local API    | `http://<computer-LAN-IP>:5095`           |
/// | Production                    | [productionApiBaseUrl]                    |
///
/// Ready-made VS Code profiles live in `.vscode/launch.json`; the exact
/// `flutter run` commands are in the README.
abstract final class Environment {
  /// Production backend. Not the default because its DNS is currently
  /// unreliable — opt in via `--dart-define` (see README).
  static const String productionApiBaseUrl =
      'https://sportico-api-khoi-g3bpg4a3dnhehng8.japaneast-01.azurewebsites.net';

  /// Defaults to the Android-emulator alias for a backend on the host
  /// machine — the most common dev loop. Every other target must pass
  /// `--dart-define=API_BASE_URL=...`; a debug warning fires otherwise
  /// (see `main.dart`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5095',
  );

  /// True when the URL was provided explicitly instead of falling back to
  /// the default above.
  static const bool hasExplicitApiBaseUrl = bool.hasEnvironment('API_BASE_URL');

  /// `local` (default) or `production`.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );
}
