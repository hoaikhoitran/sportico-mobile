/// Error payload of the backend `Result<T>` envelope.
///
/// ```json
/// { "code": "...", "message": "...", "type": "Validation", "details": ["..."] }
/// ```
class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    required this.type,
    this.details,
  });

  final String code;
  final String message;
  final String type;
  final List<String>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'Failure',
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  factory ApiError.network(String message) =>
      ApiError(code: 'NETWORK_ERROR', message: message, type: 'Network');

  factory ApiError.unknown([String? message]) => ApiError(
    code: 'UNKNOWN',
    message: message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.',
    type: 'Failure',
  );

  bool get isValidation => type == 'Validation';
  bool get isUnauthorized => type == 'Unauthorized';
  bool get isForbidden => type == 'Forbidden';
  bool get isNotFound => type == 'NotFound';

  /// User-facing Vietnamese message. Known codes get curated copy,
  /// everything else falls back to [message] / generic text.
  String get userMessage {
    final known = _codeMessages[code];
    if (known != null) return known;
    if (isValidation && details != null && details!.isNotEmpty) {
      return details!.join('\n');
    }
    if (code == 'NETWORK_ERROR') return message;
    if (message.isNotEmpty) return message;
    return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }

  static const Map<String, String> _codeMessages = {
    'AUTH_INVALID_CREDENTIALS': 'Email hoặc mật khẩu không đúng.',
    'COMMON_ACCOUNT_NOT_ACTIVE':
        'Tài khoản chưa được kích hoạt. Vui lòng xác thực email trước khi đăng nhập.',
    'AUTH_INVALID_REFRESH_TOKEN':
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'AUTH_REFRESH_TOKEN_EXPIRED':
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'AUTH_INVALID_VERIFICATION_TOKEN':
        'Liên kết xác thực không hợp lệ hoặc đã hết hạn.',
    'USER_EMAIL_ALREADY_EXISTS': 'Email này đã được đăng ký.',
    'COACH_PROFILE_ALREADY_EXISTS': 'Bạn đã đăng ký làm huấn luyện viên.',
    'SPORT_INVALID': 'Môn thể thao không hợp lệ.',
    'TRAINING_PACKAGE_NOT_FOUND': 'Không tìm thấy gói tập.',
    'TRAINING_PACKAGE_NOT_PUBLISHED': 'Gói tập này hiện chưa mở bán.',
    'TRAINING_PACKAGE_HAS_NO_SCHEDULE': 'Gói tập chưa có lịch tập.',
    'TRAINING_PACKAGE_SESSION_SLOT_FULL': 'Một số buổi tập đã hết chỗ.',
    'INVALID_TRAINING_PACKAGE_STATUS':
        'Trạng thái gói tập không cho phép thao tác này.',
    'CONCURRENCY_CONFLICT':
        'Suất cuối vừa được người khác đặt. Vui lòng thử lại.',
    'COMMON_FORBIDDEN': 'Bạn không thể thực hiện thao tác này.',
    'BOOKING_NOT_FOUND': 'Không tìm thấy đơn đăng ký.',
    'BOOKING_NOT_ACTIVE': 'Đơn đăng ký chưa ở trạng thái hoạt động.',
    'SESSION_LIMIT_EXCEEDED': 'Tất cả buổi tập trong gói đã được xếp lịch.',
    'SCHEDULE_CONFLICT':
        'Khung giờ bị trùng lịch. Vui lòng chọn thời gian khác.',
    'INVALID_TRAINING_SESSION_STATUS':
        'Buổi tập không thể chuyển sang trạng thái này.',
    'TRAINING_SESSION_NOT_OWNED': 'Bạn không có quyền với buổi tập này.',
    'TRAINING_PLAN_NOT_FOUND': 'Chưa có giáo án cho đơn đăng ký này.',
    'INVALID_TRAINING_PLAN_STATUS':
        'Trạng thái giáo án không cho phép thao tác này.',
    'LEARNER_ASSESSMENT_NOT_FOUND': 'Chưa có hồ sơ đánh giá đầu vào.',
    'PROGRESS_CHECKIN_NOT_FOUND': 'Không tìm thấy lần ghi nhận tiến độ.',
    'COACH_PROFILE_NOT_FOUND': 'Không tìm thấy hồ sơ huấn luyện viên.',
    'COACH_PROFILE_REQUIRED': 'Bạn cần đăng ký làm huấn luyện viên trước.',
    'CHAT_NOT_ALLOWED': 'Bạn không có quyền truy cập cuộc trò chuyện này.',
    'NOTIFICATION_NOT_FOUND': 'Không tìm thấy thông báo.',
    'USER_NOT_FOUND': 'Không tìm thấy tài khoản.',
    'COMMON_INTERNAL_SERVER_ERROR': 'Đã có lỗi xảy ra. Vui lòng thử lại sau.',
  };

  @override
  String toString() => 'ApiError($code, $type): $message';
}
