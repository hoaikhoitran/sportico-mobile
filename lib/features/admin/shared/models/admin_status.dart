import '../../../../core/widgets/app_badge.dart';
import '../../../training_packages/data/models/training_package.dart';

/// Central status vocabulary for the admin area.
///
/// Every value below is copied from the backend constant classes
/// (`SporticoApp.Shared/Constants/*.cs`) — the API sends and accepts these
/// exact lowercase strings. Unknown values never crash: they fall back to
/// `unknown` and are rendered with a neutral chip, so a new backend state only
/// looks unfamiliar instead of breaking the screen.
///
/// Label + chip tone live here so no screen re-implements status formatting.

/// `UserStatus` — active | inactive | banned | pending.
enum AdminUserStatus {
  active,
  inactive,
  banned,
  pending,
  unknown;

  static AdminUserStatus parse(String? raw) => switch (raw) {
    'active' => active,
    'inactive' => inactive,
    'banned' => banned,
    'pending' => pending,
    _ => unknown,
  };

  /// Value sent back to the backend (`AdminCreateUserRequest.status`).
  String get wireValue => this == unknown ? '' : name;

  String get label => switch (this) {
    active => 'Đang hoạt động',
    inactive => 'Ngừng hoạt động',
    banned => 'Bị khóa',
    pending => 'Chờ kích hoạt',
    unknown => 'Không xác định',
  };

  AppBadgeTone get tone => switch (this) {
    active => AppBadgeTone.success,
    inactive => AppBadgeTone.neutral,
    banned => AppBadgeTone.danger,
    pending => AppBadgeTone.warning,
    unknown => AppBadgeTone.neutral,
  };

  /// The statuses an admin may assign through the user form.
  static const assignable = [active, inactive, banned, pending];
}

/// Chip tone for the shared `PackageStatus` enum (owned by the catalog
/// feature). Kept here so status → style lives in exactly one place.
extension PackageStatusTone on PackageStatus {
  AppBadgeTone get tone => switch (this) {
    PackageStatus.pending => AppBadgeTone.warning,
    PackageStatus.published => AppBadgeTone.success,
    PackageStatus.rejected => AppBadgeTone.danger,
    PackageStatus.archived => AppBadgeTone.neutral,
    PackageStatus.unknown => AppBadgeTone.neutral,
  };
}

/// `PostStatusConstants` — draft | pending | published | archived | rejected.
enum AdminPostStatus {
  draft,
  pending,
  published,
  archived,
  rejected,
  unknown;

  static AdminPostStatus parse(String? raw) => switch (raw) {
    'draft' => draft,
    'pending' => pending,
    'published' => published,
    'archived' => archived,
    'rejected' => rejected,
    _ => unknown,
  };

  String get label => switch (this) {
    draft => 'Bản nháp',
    pending => 'Chờ duyệt',
    published => 'Đã đăng',
    archived => 'Đã lưu trữ',
    rejected => 'Bị từ chối',
    unknown => 'Không xác định',
  };

  AppBadgeTone get tone => switch (this) {
    draft => AppBadgeTone.neutral,
    pending => AppBadgeTone.warning,
    published => AppBadgeTone.success,
    archived => AppBadgeTone.neutral,
    rejected => AppBadgeTone.danger,
    unknown => AppBadgeTone.neutral,
  };

  /// `AdminPostService` only lets `pending` and `draft` posts be moderated.
  bool get isModeratable => this == pending || this == draft;
}

/// `ReportStatuses` — pending | reviewing | resolved | rejected.
enum ReviewReportStatus {
  pending,
  reviewing,
  resolved,
  rejected,
  unknown;

  static ReviewReportStatus parse(String? raw) => switch (raw) {
    'pending' => pending,
    'reviewing' => reviewing,
    'resolved' => resolved,
    'rejected' => rejected,
    _ => unknown,
  };

  String? get wireValue => this == unknown ? null : name;

  String get label => switch (this) {
    pending => 'Chờ xử lý',
    reviewing => 'Đang xem xét',
    resolved => 'Đã xử lý',
    rejected => 'Đã bác bỏ',
    unknown => 'Không xác định',
  };

  AppBadgeTone get tone => switch (this) {
    pending => AppBadgeTone.warning,
    reviewing => AppBadgeTone.info,
    resolved => AppBadgeTone.success,
    rejected => AppBadgeTone.neutral,
    unknown => AppBadgeTone.neutral,
  };

  /// `ReviewReportService.ResolveAsync` rejects reports that are already
  /// resolved or rejected.
  bool get isResolvable => this == pending || this == reviewing;
}

/// `ReportActions` — none | review_hidden | review_deleted.
abstract final class ReviewReportActions {
  static String label(String? raw) => switch (raw) {
    'none' => 'Không xử lý đánh giá',
    'review_hidden' => 'Đã ẩn đánh giá',
    'review_deleted' => 'Đã xóa đánh giá',
    null || '' => '—',
    _ => raw,
  };
}

/// `ReviewStatuses` — active | hidden | deleted (status of the reported review).
abstract final class ReviewStatusLabels {
  static String label(String? raw) => switch (raw) {
    'active' => 'Đang hiển thị',
    'hidden' => 'Đã ẩn',
    'deleted' => 'Đã xóa',
    null || '' => '—',
    _ => raw,
  };
}

/// `PayoutAccountStatuses` — pending | verified | rejected.
enum PayoutAccountStatus {
  pending,
  verified,
  rejected,
  unknown;

  static PayoutAccountStatus parse(String? raw) => switch (raw) {
    'pending' => pending,
    'verified' => verified,
    'rejected' => rejected,
    _ => unknown,
  };

  String get label => switch (this) {
    pending => 'Chờ xác minh',
    verified => 'Đã xác minh',
    rejected => 'Bị từ chối',
    unknown => 'Không xác định',
  };

  AppBadgeTone get tone => switch (this) {
    pending => AppBadgeTone.warning,
    verified => AppBadgeTone.success,
    rejected => AppBadgeTone.danger,
    unknown => AppBadgeTone.neutral,
  };

  bool get isPending => this == pending;
}

/// `WithdrawalRequestStatuses` —
/// pending | approved | processing | paid | rejected | failed | cancelled.
enum WithdrawalStatus {
  pending,
  approved,
  processing,
  paid,
  rejected,
  failed,
  cancelled,
  unknown;

  static WithdrawalStatus parse(String? raw) => switch (raw) {
    'pending' => pending,
    'approved' => approved,
    'processing' => processing,
    'paid' => paid,
    'rejected' => rejected,
    'failed' => failed,
    'cancelled' => cancelled,
    _ => unknown,
  };

  /// `WithdrawalService` returns 400 for a status filter it does not know, so
  /// `unknown` is never sent as a query value.
  String? get wireValue => this == unknown ? null : name;

  String get label => switch (this) {
    pending => 'Chờ duyệt',
    approved => 'Đã duyệt',
    processing => 'Đang chuyển tiền',
    paid => 'Đã thanh toán',
    rejected => 'Bị từ chối',
    failed => 'Thất bại',
    cancelled => 'Đã hủy',
    unknown => 'Không xác định',
  };

  AppBadgeTone get tone => switch (this) {
    pending => AppBadgeTone.warning,
    approved => AppBadgeTone.info,
    processing => AppBadgeTone.brand,
    paid => AppBadgeTone.success,
    rejected => AppBadgeTone.danger,
    failed => AppBadgeTone.danger,
    cancelled => AppBadgeTone.neutral,
    unknown => AppBadgeTone.neutral,
  };

  /// Statuses the backend accepts on the admin list filter.
  static const filterable = [
    pending,
    approved,
    processing,
    paid,
    rejected,
    failed,
    cancelled,
  ];
}

/// Roles as returned by the backend (`RoleConstants`).
abstract final class AdminRoles {
  static const learner = 'learner';
  static const coach = 'coach';
  static const admin = 'admin';

  static const all = [learner, coach, admin];

  static String label(String role) => switch (role) {
    learner => 'Người tập',
    coach => 'Huấn luyện viên',
    admin => 'Quản trị viên',
    _ => role,
  };

  static AppBadgeTone tone(String role) => switch (role) {
    admin => AppBadgeTone.brand,
    coach => AppBadgeTone.info,
    learner => AppBadgeTone.neutral,
    _ => AppBadgeTone.neutral,
  };
}

/// Masks a bank account number for list/summary surfaces: only the last four
/// digits stay readable. Full numbers are shown solely on the payout-account
/// detail screen, where an admin needs them to verify the account.
String maskAccountNumber(String? accountNumber) {
  final value = accountNumber?.trim() ?? '';
  if (value.isEmpty) return '—';
  if (value.length <= 4) return '••••$value';
  return '•••• ${value.substring(value.length - 4)}';
}
