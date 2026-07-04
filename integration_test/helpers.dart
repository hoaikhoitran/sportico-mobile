import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/app/app.dart';
import 'package:group_prj/core/network/dio_client.dart';

/// Records every real HTTP exchange the app makes so the run log doubles as
/// API-verification evidence. Tokens are never printed — only whether the
/// Authorization header was present.
class ApiEvidenceRecorder extends Interceptor {
  final List<String> lines = [];

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _record(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _record(RequestOptions options, int? status) {
    final hasAuth = options.headers['Authorization'] != null;
    final query = options.uri.query.isEmpty ? '' : '?${options.uri.query}';
    lines.add(
      'API-EVIDENCE | ${options.method} ${options.uri.path}$query '
      '| status=${status ?? 'ERR'} | auth=${hasAuth ? 'Bearer(masked)' : 'none'}',
    );
  }

  void dump(String phase) {
    debugPrint('===== API EVIDENCE ($phase) =====');
    for (final line in lines) {
      debugPrint(line);
    }
    debugPrint('===== END API EVIDENCE ($phase) — ${lines.length} calls =====');
  }
}

/// Boots the real app with real networking and attaches the recorder.
Future<(ProviderContainer, ApiEvidenceRecorder)> pumpRealApp(
  WidgetTester tester,
) async {
  final container = ProviderContainer();
  final recorder = ApiEvidenceRecorder();
  container.read(dioProvider).interceptors.add(recorder);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const SporticoApp(),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 2));
  return (container, recorder);
}

/// Waits (polling real async work) until [finder] appears or [timeout] ends.
Future<bool> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 300));
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 300));
      return true;
    }
  }
  return false;
}

Future<void> settle(WidgetTester tester,
    [Duration wait = const Duration(seconds: 1)]) async {
  await tester.pump(wait);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Scrolls a Scrollable until [finder] is visible, then taps it.
Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester, const Duration(milliseconds: 300));
  await tester.tap(finder, warnIfMissed: false);
  await settle(tester);
}
