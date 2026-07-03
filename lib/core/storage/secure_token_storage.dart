import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted auth session (tokens rotate on every refresh).
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  /// Backend refresh requires `{ email, refreshToken }`.
  final String email;
}

/// Secure token persistence — never store tokens in SharedPreferences.
class SecureTokenStorage {
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'sportico_access_token';
  static const _kRefreshToken = 'sportico_refresh_token';
  static const _kExpiresAt = 'sportico_expires_at';
  static const _kEmail = 'sportico_auth_email';

  Future<void> saveSession(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: session.accessToken),
      _storage.write(key: _kRefreshToken, value: session.refreshToken),
      _storage.write(
        key: _kExpiresAt,
        value: session.expiresAt?.toIso8601String(),
      ),
      _storage.write(key: _kEmail, value: session.email),
    ]);
  }

  Future<AuthSession?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _kAccessToken),
      _storage.read(key: _kRefreshToken),
      _storage.read(key: _kExpiresAt),
      _storage.read(key: _kEmail),
    ]);
    final [accessToken, refreshToken, expiresAt, email] = values;
    if (accessToken == null || refreshToken == null || email == null) {
      return null;
    }
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt != null ? DateTime.tryParse(expiresAt) : null,
      email: email,
    );
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kExpiresAt),
      _storage.delete(key: _kEmail),
    ]);
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage(const FlutterSecureStorage());
});
