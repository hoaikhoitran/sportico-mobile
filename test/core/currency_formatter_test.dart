import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:group_prj/core/utils/currency_formatter.dart';

void main() {
  setUpAll(() {
    Intl.defaultLocale = 'vi_VN';
  });

  test('formats VND with dot separators and ₫ symbol', () {
    final formatted = CurrencyFormatter.vnd(1000000);
    expect(formatted, contains('1.000.000'));
    expect(formatted, contains('₫'));
  });

  test('parses numeric and string amounts', () {
    expect(CurrencyFormatter.parseAmount(106250), 106250);
    expect(CurrencyFormatter.parseAmount('0.15'), 0.15);
    expect(CurrencyFormatter.parseAmount(null), 0);
    expect(CurrencyFormatter.parseAmount('abc'), 0);
  });
}
