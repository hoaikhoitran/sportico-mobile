import '../../../../../core/utils/date_formatter.dart';

/// `PlatformCommissionResponse` / `UpdatePlatformCommissionRequest`.
///
/// **Representation:** the API speaks *percent*, not a fraction. A 15% cut is
/// `commissionPercent: 15`, not `0.15` — the backend divides by 100 before it
/// persists the rate (`PlatformSettingService`). The validator accepts 0–100
/// with at most two decimals.
class PlatformCommission {
  const PlatformCommission({
    required this.commissionPercent,
    this.updatedAt,
    this.updatedByUserId,
  });

  /// 0–100.
  final num commissionPercent;
  final DateTime? updatedAt;
  final String? updatedByUserId;

  /// e.g. `15%` / `12,5%`.
  String get percentLabel {
    final value = commissionPercent;
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString().replaceAll('.', ',');
    return '$text%';
  }

  factory PlatformCommission.fromJson(Map<String, dynamic> json) {
    return PlatformCommission(
      commissionPercent: (json['commissionPercent'] as num?) ?? 0,
      updatedAt: DateFormatter.parseUtc(json['updatedAt'] as String?),
      updatedByUserId: json['updatedByUserId'] as String?,
    );
  }
}

/// Client-side mirror of `UpdatePlatformCommissionRequestValidator`.
abstract final class CommissionRules {
  static const min = 0;
  static const max = 100;

  /// Returns a Vietnamese error, or null when [raw] is a valid percent.
  static String? validate(String? raw) {
    final text = (raw ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return 'Vui lòng nhập tỷ lệ hoa hồng.';

    final value = num.tryParse(text);
    if (value == null) return 'Tỷ lệ hoa hồng phải là số.';
    if (value < min || value > max) {
      return 'Tỷ lệ hoa hồng phải từ $min đến $max.';
    }

    // The backend rejects more than two decimal places.
    final decimals = text.contains('.')
        ? text.split('.').last.replaceAll(RegExp(r'0+$'), '').length
        : 0;
    if (decimals > 2) return 'Tỷ lệ hoa hồng tối đa 2 chữ số thập phân.';

    return null;
  }

  /// Parses user input into the value sent as `commissionPercent`.
  static num? parse(String? raw) =>
      num.tryParse((raw ?? '').trim().replaceAll(',', '.'));
}
