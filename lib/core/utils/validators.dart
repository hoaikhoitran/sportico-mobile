/// Inline form validators with Vietnamese messages.
///
/// Rules mirror the backend data annotations (docs/api/auth.md).
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập email.';
    if (v.length > 320 || !_email.hasMatch(v)) return 'Email không hợp lệ.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
    if (v.length > 100) return 'Mật khẩu tối đa 100 ký tự.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập lại mật khẩu.';
    if (value != original) return 'Mật khẩu nhập lại không khớp.';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập họ tên.';
    if (v.length < 2 || v.length > 150) {
      return 'Họ tên phải từ 2 đến 150 ký tự.';
    }
    return null;
  }

  static String? required(String? value, [String label = 'trường này']) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label.';
    }
    return null;
  }

  /// Coach headline: required, 5–255 chars (backend rule).
  static String? headline(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập tiêu đề giới thiệu.';
    if (v.length < 5 || v.length > 255) {
      return 'Tiêu đề phải từ 5 đến 255 ký tự.';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String label = 'giá trị']) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập $label.';
    final parsed = num.tryParse(v.replaceAll('.', '').replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return '$label phải là số dương.';
    return null;
  }

  static String? optionalRange(
    String? value,
    num min,
    num max, [
    String label = 'Giá trị',
  ]) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final parsed = num.tryParse(v);
    if (parsed == null || parsed < min || parsed > max) {
      return '$label phải từ $min đến $max.';
    }
    return null;
  }
}
