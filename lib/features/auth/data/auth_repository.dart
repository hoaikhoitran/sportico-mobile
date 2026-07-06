import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/storage/secure_token_storage.dart';
import 'auth_api.dart';
import 'models/auth_tokens.dart';
import 'models/current_user.dart';

/// Auth use-cases: login persists the session, logout is client-side only
/// (no logout endpoint exists — tokens are simply discarded).
class AuthRepository {
  AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final SecureTokenStorage _storage;

  Future<ApiResult<AuthTokens>> login(String email, String password) async {
    final result = await _api.login(email, password);
    if (result case ApiSuccess(data: final tokens)) {
      await _storage.saveSession(
        AuthSession(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresAt: tokens.expiresAt,
          email: email,
        ),
      );
    }
    return result;
  }

  Future<ApiResult<String>> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _api.register(email: email, password: password, fullName: fullName);
  }

  Future<ApiResult<String>> verifyEmail(String token) =>
      _api.verifyEmail(token);

  Future<ApiResult<String>> resendVerificationEmail(String email) =>
      _api.resendVerificationEmail(email);

  Future<ApiResult<String>> forgotPassword(String email) =>
      _api.forgotPassword(email);

  Future<ApiResult<String>> resetPassword({
    required String token,
    required String newPassword,
  }) => _api.resetPassword(token: token, newPassword: newPassword);

  Future<ApiResult<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _api.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  Future<ApiResult<CurrentUser>> updateMe({String? fullName, String? phone}) =>
      _api.updateMe(fullName: fullName, phone: phone);

  Future<ApiResult<CurrentUser>> getMe() => _api.getMe();

  Future<AuthSession?> restoreSession() => _storage.readSession();

  /// Proactively rotates the token pair so newly granted roles (e.g. `coach`
  /// right after onboarding) land in the access token — the backend
  /// authorizes from JWT claims, and the 401-refresh interceptor never fires
  /// on 403.
  Future<void> forceTokenRefresh() async {
    final session = await _storage.readSession();
    if (session == null) return;
    final result = await _api.refreshToken(
      email: session.email,
      refreshToken: session.refreshToken,
    );
    if (result case ApiSuccess(data: final tokens)) {
      await _storage.saveSession(
        AuthSession(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresAt: tokens.expiresAt,
          email: session.email,
        ),
      );
    }
  }

  Future<void> logout() => _storage.clear();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(secureTokenStorageProvider),
  );
});
