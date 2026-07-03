import 'package:dio/dio.dart';

import '../storage/secure_token_storage.dart';

/// Attaches `Authorization: Bearer <accessToken>` to every request.
///
/// Public auth endpoints work with or without the header, so no route
/// filtering is needed here.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final SecureTokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
