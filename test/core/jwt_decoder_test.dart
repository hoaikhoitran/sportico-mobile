import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:group_prj/core/utils/jwt_decoder.dart';

String _fakeJwt(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode(payload)}.sig';
}

void main() {
  group('JwtDecoder.roles', () {
    test('single role as string (JwtSecurityTokenHandler short name)', () {
      final token = _fakeJwt({'role': 'learner'});
      expect(JwtDecoder.roles(token), ['learner']);
    });

    test('multiple roles as array', () {
      final token = _fakeJwt({
        'role': ['learner', 'coach'],
      });
      expect(JwtDecoder.roles(token), ['learner', 'coach']);
    });

    test('full URI claim form is handled defensively', () {
      final token = _fakeJwt({
        'http://schemas.microsoft.com/ws/2008/06/identity/claims/role': 'admin',
      });
      expect(JwtDecoder.roles(token), ['admin']);
    });

    test('garbage token yields no roles instead of crashing', () {
      expect(JwtDecoder.roles('not-a-jwt'), isEmpty);
      expect(JwtDecoder.roles(''), isEmpty);
    });
  });

  test('expiry is decoded from exp seconds', () {
    final expiresAt = DateTime.utc(2026, 7, 1, 12);
    final token = _fakeJwt({'exp': expiresAt.millisecondsSinceEpoch ~/ 1000});
    expect(JwtDecoder.expiry(token), expiresAt);
  });
}
