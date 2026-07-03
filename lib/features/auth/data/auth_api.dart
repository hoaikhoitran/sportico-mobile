import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import 'models/auth_tokens.dart';
import 'models/current_user.dart';

/// Raw auth endpoints (docs/api/auth.md + docs/api/users.md).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<ApiResult<AuthTokens>> login(String email, String password) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      ),
      (data) => AuthTokens.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Non-generic envelope: `{ isSuccess, message }`.
  Future<ApiResult<String>> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    return safeMessageCall(
      () => _dio.post(
        ApiEndpoints.register,
        data: {'email': email, 'password': password, 'fullName': fullName},
      ),
    );
  }

  /// Non-generic envelope: `{ isSuccess, message }`.
  Future<ApiResult<String>> verifyEmail(String token) {
    return safeMessageCall(
      () =>
          _dio.get(ApiEndpoints.verifyEmail, queryParameters: {'token': token}),
    );
  }

  Future<ApiResult<AuthTokens>> refreshToken({
    required String email,
    required String refreshToken,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.refreshToken,
        data: {'email': email, 'refreshToken': refreshToken},
      ),
      (data) => AuthTokens.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<CurrentUser>> getMe() {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.me),
      (data) => CurrentUser.fromJson(data as Map<String, dynamic>),
    );
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
