import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/features/admin/settings/data/models/platform_commission.dart';

/// Mirrors `UpdatePlatformCommissionRequestValidator`: 0–100, max 2 decimals.
void main() {
  group('CommissionRules.validate', () {
    test('accepts the bounds and a normal rate', () {
      expect(CommissionRules.validate('0'), isNull);
      expect(CommissionRules.validate('15'), isNull);
      expect(CommissionRules.validate('100'), isNull);
    });

    test('accepts up to two decimals, in either decimal separator', () {
      expect(CommissionRules.validate('12.5'), isNull);
      expect(CommissionRules.validate('12,55'), isNull);
    });

    test('rejects an empty value', () {
      expect(CommissionRules.validate(''), contains('Vui lòng nhập'));
      expect(CommissionRules.validate(null), isNotNull);
    });

    test('rejects a value outside 0–100', () {
      expect(CommissionRules.validate('-1'), contains('từ 0 đến 100'));
      expect(CommissionRules.validate('101'), contains('từ 0 đến 100'));
    });

    test('rejects more than two decimal places', () {
      expect(
        CommissionRules.validate('12.345'),
        contains('2 chữ số thập phân'),
      );
    });

    test('rejects non-numeric input', () {
      expect(CommissionRules.validate('mười lăm'), contains('phải là số'));
    });
  });

  group('CommissionRules.parse', () {
    test('parses both decimal separators into a percent value', () {
      expect(CommissionRules.parse('15'), 15);
      expect(CommissionRules.parse('12,5'), 12.5);
      expect(CommissionRules.parse(' 7.25 '), 7.25);
    });

    test('returns null for input that is not a number', () {
      expect(CommissionRules.parse('abc'), isNull);
    });
  });
}
