import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_token_storage.dart';
import 'api_endpoints.dart';

/// Notifies listeners when the refresh flow fails and the user must sign in
/// again. The auth controller listens and resets its state; the router then
/// redirects to login.
class SessionExpiredNotifier extends ChangeNotifier {
  void notifySessionExpired() => notifyListeners();
}

/// On 401: refreshes the token pair once (`{ email, refreshToken }`, tokens
/// are rotated server-side), retries the failed request exactly once, and on
/// refresh failure clears the session and signals [SessionExpiredNotifier].
///
/// `QueuedInterceptorsWrapper` serializes concurrent 401s so only one refresh
/// call reaches the backend.
class TokenRefreshInterceptor extends QueuedInterceptorsWrapper {
  TokenRefreshInterceptor({
    required SecureTokenStorage storage,
    required Dio retryDio,
    required SessionExpiredNotifier sessionExpired,
  }) : _storage = storage,
       _retryDio = retryDio,
       _sessionExpired = sessionExpired;

  final SecureTokenStorage _storage;

  /// Bare client (no interceptors) for the refresh call and the retry —
  /// prevents interceptor recursion.
  final Dio _retryDio;

  final SessionExpiredNotifier _sessionExpired;

  static const _retriedKey = 'sportico_retried_after_refresh';

  static const _noRefreshPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.refreshToken,
    ApiEndpoints.verifyEmail,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final options = err.requestOptions;

    final shouldRefresh =
        response?.statusCode == 401 &&
        !_noRefreshPaths.contains(options.path) &&
        options.extra[_retriedKey] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    final session = await _storage.readSession();
    if (session == null) {
      await _expire();
      handler.next(err);
      return;
    }

    final newAccessToken = await _refresh(session);
    if (newAccessToken == null) {
      await _expire();
      handler.next(err);
      return;
    }

    try {
      options.extra[_retriedKey] = true;
      options.headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _retryDio.fetch<dynamic>(options);
      handler.resolve(retryResponse);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  /// Returns the new access token, or null when refresh fails.
  Future<String?> _refresh(AuthSession session) async {
    try {
      final response = await _retryDio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'email': session.email, 'refreshToken': session.refreshToken},
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['isSuccess'] != true) {
        return null;
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;

      final accessToken = data['accessToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) return null;

      await _storage.saveSession(
        AuthSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: DateTime.tryParse(data['expiresAt'] as String? ?? ''),
          email: session.email,
        ),
      );
      return accessToken;
    } on DioException {
      return null;
    }
  }

  Future<void> _expire() async {
    await _storage.clear();
    _sessionExpired.notifySessionExpired();
  }
}
