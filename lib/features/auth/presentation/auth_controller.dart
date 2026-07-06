import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/jwt_decoder.dart';
import '../data/auth_repository.dart';
import '../data/models/current_user.dart';

enum AuthStatus { restoring, unauthenticated, authenticated }

/// Role names as returned by the backend (`learner`, `coach`, `admin`).
abstract final class Roles {
  static const learner = 'learner';
  static const coach = 'coach';
  static const admin = 'admin';
}

class AuthState {
  const AuthState({required this.status, this.user, this.roles = const []});

  final AuthStatus status;

  /// Full profile from `GET /api/users/me`; may be null right after login
  /// until the profile call completes (roles then come from the JWT).
  final CurrentUser? user;

  final List<String> roles;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLearner => roles.contains(Roles.learner);
  bool get isCoach => roles.contains(Roles.coach);
  bool get isAdmin => roles.contains(Roles.admin);

  /// Admin-only accounts get the "not supported on mobile" screen.
  bool get isAdminOnly => isAdmin && !isLearner && !isCoach;

  const AuthState.restoring() : this(status: AuthStatus.restoring);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // The refresh interceptor signals here when the session can no longer be
    // renewed; tokens are already cleared at that point.
    final sessionExpired = ref.watch(sessionExpiredNotifierProvider);
    void onExpired() => state = const AuthState.unauthenticated();
    sessionExpired.addListener(onExpired);
    ref.onDispose(() => sessionExpired.removeListener(onExpired));

    Future.microtask(_restoreSession);
    return const AuthState.restoring();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restoreSession() async {
    final session = await _repository.restoreSession();
    if (session == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    // JWT roles are a fast UI hint; /users/me is the authoritative source.
    state = AuthState(
      status: AuthStatus.authenticated,
      roles: JwtDecoder.roles(session.accessToken),
    );
    await _loadProfile();
  }

  /// Fetches `/users/me`. On auth failure the refresh interceptor either
  /// renews the token transparently or expires the session; a network error
  /// keeps the JWT-derived state so the app stays usable offline-ish.
  Future<void> _loadProfile() async {
    final result = await _repository.getMe();
    if (result case ApiSuccess(data: final user)) {
      if (state.status == AuthStatus.authenticated) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          roles: user.roles.isNotEmpty ? user.roles : state.roles,
        );
      }
    }
  }

  /// Returns null on success, otherwise the error to display inline.
  Future<ApiError?> login(String email, String password) async {
    final result = await _repository.login(email.trim(), password);
    switch (result) {
      case ApiSuccess(data: final tokens):
        state = AuthState(
          status: AuthStatus.authenticated,
          roles: JwtDecoder.roles(tokens.accessToken),
        );
        await _loadProfile();
        return null;
      case ApiFailure(:final error):
        return error;
    }
  }

  Future<ApiResult<String>> register({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _repository.register(
      email: email.trim(),
      password: password,
      fullName: fullName.trim(),
    );
  }

  Future<ApiResult<String>> verifyEmail(String token) =>
      _repository.verifyEmail(token.trim());

  Future<ApiResult<String>> resendVerificationEmail(String email) =>
      _repository.resendVerificationEmail(email.trim());

  Future<ApiResult<String>> forgotPassword(String email) =>
      _repository.forgotPassword(email.trim());

  Future<ApiResult<String>> resetPassword({
    required String token,
    required String newPassword,
  }) => _repository.resetPassword(token: token.trim(), newPassword: newPassword);

  Future<ApiResult<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  /// Updates the profile and reflects the result in [AuthState].
  Future<ApiError?> updateProfile({String? fullName, String? phone}) async {
    final result = await _repository.updateMe(fullName: fullName, phone: phone);
    switch (result) {
      case ApiSuccess():
        await _loadProfile();
        return null;
      case ApiFailure(:final error):
        return error;
    }
  }

  /// Re-fetches the profile (e.g. after a profile edit).
  Future<void> refreshProfile() => _loadProfile();

  /// After a role change (coach onboarding): rotates the token pair so the
  /// new role is present in the JWT, then reloads the profile.
  Future<void> onRolesChanged() async {
    await _repository.forceTokenRefresh();
    await _loadProfile();
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
