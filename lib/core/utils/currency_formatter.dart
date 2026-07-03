import 'package:intl/intl.dart';

/// VND display formatting: `1.000.000 ₫`.
abstract final class CurrencyFormatter {
  static final NumberFormat _vnd = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static String vnd(num amount) => _vnd.format(amount);

  /// Parses backend decimal money values (num or numeric string).
  static num parseAmount(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}
