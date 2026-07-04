import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'vi_VN';
  await initializeDateFormatting('vi');
  _logEnvironment();
  runApp(const ProviderScope(child: SporticoApp()));
}

/// Debug-only startup banner so a wrong backend target is obvious
/// immediately instead of surfacing as confusing network errors.
void _logEnvironment() {
  if (!kDebugMode) return;
  debugPrint(
    '[Sportico] APP_ENV=${AppConfig.environment} '
    'API_BASE_URL=${AppConfig.apiBaseUrl}',
  );
  if (!Environment.hasExplicitApiBaseUrl) {
    debugPrint(
      '[Sportico] WARNING: no --dart-define=API_BASE_URL was provided; '
      'falling back to ${AppConfig.apiBaseUrl} (local backend via the '
      'Android-emulator alias). This only works on an Android emulator '
      'with the API running on this machine. For the iOS simulator use '
      'http://127.0.0.1:5095, for a physical phone use your computer '
      'LAN IP, for production use ${Environment.productionApiBaseUrl}. '
      'See README or .vscode/launch.json for ready-made commands.',
    );
  }
}
