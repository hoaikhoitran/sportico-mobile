import 'dart:convert';

/// Minimal JWT payload decoding — **UI hints only** (roles, expiry).
/// Authorization is always enforced by the backend.
abstract final class JwtDecoder {
  static Map<String, dynamic>? decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// The backend serializes `ClaimTypes.Role` via `JwtSecurityTokenHandler`,
  /// which shortens it to `role`; a single role is a string, multiple roles an
  /// array. The full URI form is handled defensively.
  static List<String> roles(String token) {
    final payload = decodePayload(token);
    if (payload == null) return const [];
    final raw =
        payload['role'] ??
        payload['roles'] ??
        payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    if (raw is String) return [raw];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  static DateTime? expiry(String token) {
    final payload = decodePayload(token);
    final exp = payload?['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  }
}
