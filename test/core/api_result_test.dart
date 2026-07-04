import 'package:flutter_test/flutter_test.dart';

import 'package:group_prj/core/network/api_error.dart';
import 'package:group_prj/core/network/api_result.dart';
import 'package:group_prj/core/network/paged_result.dart';

void main() {
  group('ApiResult.fromEnvelope', () {
    test('parses success envelope', () {
      final result = ApiResult.fromEnvelope<String>({
        'isSuccess': true,
        'data': 'hello',
        'error': null,
      }, (data) => data as String);
      expect(result, isA<ApiSuccess<String>>());
      expect(result.requireData, 'hello');
    });

    test('parses failure envelope with error node', () {
      final result = ApiResult.fromEnvelope<String>({
        'isSuccess': false,
        'data': null,
        'error': {
          'code': 'BOOKING_NOT_ACTIVE',
          'message': 'Booking is not active',
          'type': 'Conflict',
          'details': null,
        },
      }, (data) => data as String);
      expect(result, isA<ApiFailure<String>>());
      expect(result.requireError.code, 'BOOKING_NOT_ACTIVE');
      // Known code gets curated Vietnamese copy.
      expect(result.requireError.userMessage, contains('hoạt động'));
    });

    test('HTTP 200 with isSuccess:false is treated as failure', () {
      final result = ApiResult.fromEnvelope<int>({
        'isSuccess': false,
        'data': null,
        'error': null,
      }, (data) => data as int);
      expect(result.isSuccess, isFalse);
    });

    test('validation details drive the user message', () {
      final error = ApiError.fromJson({
        'code': 'COMMON_VALIDATION_ERROR',
        'message': 'Validation failed',
        'type': 'Validation',
        'details': ['Email không hợp lệ', 'Mật khẩu quá ngắn'],
      });
      expect(error.isValidation, isTrue);
      expect(error.userMessage, contains('Email không hợp lệ'));
      expect(error.userMessage, contains('Mật khẩu quá ngắn'));
    });
  });

  group('ApiResult.fromMessageEnvelope', () {
    test('parses the non-generic register/verify-email envelope', () {
      final result = ApiResult.fromMessageEnvelope({
        'isSuccess': true,
        'message': 'Registration successful',
      });
      expect(result.requireData, 'Registration successful');
    });
  });

  group('PagedResult', () {
    test('parses items and paging metadata', () {
      final paged = PagedResult.fromJson({
        'items': [
          {'id': 'a'},
          {'id': 'b'},
        ],
        'pageNumber': 2,
        'pageSize': 10,
        'totalCount': 12,
        'totalPages': 2,
        'hasPrevious': true,
        'hasNext': false,
      }, (json) => json['id'] as String);
      expect(paged.items, ['a', 'b']);
      expect(paged.pageNumber, 2);
      expect(paged.hasNext, isFalse);
      expect(paged.hasPrevious, isTrue);
    });

    test('tolerates missing fields', () {
      final paged = PagedResult.fromJson({}, (json) => json);
      expect(paged.items, isEmpty);
      expect(paged.pageNumber, 1);
      expect(paged.hasNext, isFalse);
    });
  });
}
