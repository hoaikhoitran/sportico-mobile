import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import '../storage/secure_token_storage.dart';
import 'auth_interceptor.dart';
import 'token_refresh_interceptor.dart';

final sessionExpiredNotifierProvider = Provider<SessionExpiredNotifier>((ref) {
  return SessionExpiredNotifier();
});

/// Main HTTP client: bearer attachment + transparent token refresh.
final dioProvider = Provider<Dio>((ref) {
  final options = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: {'Accept': 'application/json'},
  );

  final dio = Dio(options);
  final storage = ref.watch(secureTokenStorageProvider);

  dio.interceptors.addAll([
    AuthInterceptor(storage),
    TokenRefreshInterceptor(
      storage: storage,
      retryDio: Dio(options),
      sessionExpired: ref.watch(sessionExpiredNotifierProvider),
    ),
    if (kDebugMode) LogInterceptor(requestBody: false, responseBody: false),
  ]);

  return dio;
});
