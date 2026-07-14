import 'package:dio/dio.dart';
import 'package:group_prj/core/network/api_error.dart';
import 'package:group_prj/core/network/api_result.dart';
import 'package:group_prj/core/network/paged_result.dart';
import 'package:group_prj/features/admin/dashboard/data/admin_dashboard_api.dart';
import 'package:group_prj/features/admin/dashboard/data/models/admin_dashboard.dart';
import 'package:group_prj/features/admin/moderation/data/admin_moderation_api.dart';
import 'package:group_prj/features/admin/moderation/data/models/admin_post.dart';
import 'package:group_prj/features/admin/moderation/data/models/coach_payout_account.dart';
import 'package:group_prj/features/admin/moderation/data/models/review_report.dart';
import 'package:group_prj/features/admin/shared/models/admin_status.dart';
import 'package:group_prj/features/admin/users/data/admin_users_api.dart';
import 'package:group_prj/features/admin/users/data/models/admin_user.dart';
import 'package:group_prj/features/admin/withdrawals/data/admin_withdrawals_api.dart';
import 'package:group_prj/features/admin/withdrawals/data/models/withdrawal_request.dart';
import 'package:group_prj/features/training_packages/data/models/training_package.dart';

/// Test doubles for the admin APIs. Every fake subclasses the real API so the
/// production providers can be overridden without touching Dio.

PagedResult<T> pageOf<T>(
  List<T> items, {
  int pageNumber = 1,
  bool hasNext = false,
  int? totalCount,
}) {
  return PagedResult(
    items: items,
    pageNumber: pageNumber,
    pageSize: 10,
    totalCount: totalCount ?? items.length,
    totalPages: hasNext ? pageNumber + 1 : pageNumber,
    hasPrevious: pageNumber > 1,
    hasNext: hasNext,
  );
}

ApiError get forbiddenError => const ApiError(
  code: 'COMMON_FORBIDDEN',
  message: 'Forbidden',
  type: 'Forbidden',
);

AdminUser adminUser(
  String id, {
  String name = 'Người dùng',
  AdminUserStatus status = AdminUserStatus.active,
  List<String> roles = const ['learner'],
}) {
  return AdminUser(
    id: id,
    email: '$id@sportico.vn',
    fullName: name,
    status: status,
    roles: roles,
    createdAt: DateTime(2026, 1, 1),
  );
}

class FakeAdminUsersApi extends AdminUsersApi {
  FakeAdminUsersApi({
    required this.pages,
    this.details = const {},
    this.failOnPage,
    this.failList = false,
  }) : super(Dio());

  /// Page number → items served for it.
  final Map<int, List<AdminUser>> pages;

  /// User id → the identity `GET /admin/users/{id}` resolves to.
  final Map<String, AdminUser> details;

  /// Page number that must fail (next-page failure test).
  final int? failOnPage;
  final bool failList;

  final List<AdminUserFilter> filtersSeen = [];
  int listCalls = 0;
  int deactivateCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<ApiResult<PagedResult<AdminUser>>> list({
    AdminUserFilter filter = const AdminUserFilter(),
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    listCalls++;
    filtersSeen.add(filter);

    if (failList || pageNumber == failOnPage) {
      return ApiFailure(forbiddenError);
    }
    // A filtered query returns a narrower result set.
    if (filter.hasActiveFilters && pageNumber == 1) {
      return ApiSuccess(pageOf([adminUser('filtered')], totalCount: 1));
    }
    final items = pages[pageNumber] ?? const <AdminUser>[];
    return ApiSuccess(
      pageOf(
        items,
        pageNumber: pageNumber,
        hasNext: pages.containsKey(pageNumber + 1),
        totalCount: pages.values.fold<int>(0, (sum, page) => sum + page.length),
      ),
    );
  }

  @override
  Future<ApiResult<AdminUser>> detail(String id) async =>
      ApiSuccess(details[id] ?? adminUser(id));

  @override
  Future<ApiResult<AdminUser>> create(AdminCreateUserRequest request) async {
    createCalls++;
    return ApiSuccess(adminUser('new', name: request.fullName));
  }

  @override
  Future<ApiResult<AdminUser>> update(
    String id,
    AdminUpdateUserRequest request,
  ) async {
    updateCalls++;
    return ApiSuccess(adminUser(id, name: request.fullName));
  }

  @override
  Future<ApiResult<AdminUser>> deactivate(String id) async {
    deactivateCalls++;
    return ApiSuccess(adminUser(id, status: AdminUserStatus.inactive));
  }
}

class FakeAdminDashboardApi extends AdminDashboardApi {
  FakeAdminDashboardApi({this.dashboard, this.error}) : super(Dio());

  final AdminDashboard? dashboard;
  final ApiError? error;
  final List<DashboardFilter> filtersSeen = [];

  @override
  Future<ApiResult<AdminDashboard>> load(DashboardFilter filter) async {
    filtersSeen.add(filter);
    if (error != null) return ApiFailure(error!);
    return ApiSuccess(dashboard!);
  }
}

AdminDashboard sampleDashboard() => AdminDashboard.fromJson({
  'totalUsers': 120,
  'totalLearners': 90,
  'totalCoaches': 30,
  'publishedPackages': 45,
  'totalBookings': 200,
  'activeBookings': 20,
  'completedBookings': 170,
  'cancelledBookings': 10,
  'grossRevenue': 150000000,
  'platformFeeRevenue': 22500000,
  'coachPayable': 127500000,
  'totalWithdrawnPaid': 100000000,
  'pendingWithdrawals': 3,
  'processingWithdrawals': 1,
  'paidWithdrawals': 25,
  'failedWithdrawals': 2,
});

class FakeAdminModerationApi extends AdminModerationApi {
  FakeAdminModerationApi({
    this.packages = const [],
    this.posts = const [],
    this.payoutAccounts = const [],
    this.reports = const [],
    this.approveDelay = Duration.zero,
  }) : super(Dio());

  final List<TrainingPackage> packages;
  final List<AdminPost> posts;
  final List<CoachPayoutAccount> payoutAccounts;
  final List<ReviewReport> reports;

  /// Keeps an approve in flight long enough to test double-tap protection.
  final Duration approveDelay;

  int approvePackageCalls = 0;
  int rejectPackageCalls = 0;
  String? lastRejectReason;

  @override
  Future<ApiResult<PagedResult<TrainingPackage>>> pendingPackages({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async => ApiSuccess(pageOf(packages));

  @override
  Future<ApiResult<TrainingPackage>> approvePackage(String id) async {
    approvePackageCalls++;
    if (approveDelay > Duration.zero) await Future.delayed(approveDelay);
    return ApiSuccess(packages.first);
  }

  @override
  Future<ApiResult<TrainingPackage>> rejectPackage(
    String id,
    String reason,
  ) async {
    rejectPackageCalls++;
    lastRejectReason = reason;
    return ApiSuccess(packages.first);
  }

  @override
  Future<ApiResult<PagedResult<AdminPost>>> pendingPosts({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async => ApiSuccess(pageOf(posts));

  @override
  Future<ApiResult<PagedResult<CoachPayoutAccount>>> pendingPayoutAccounts({
    int pageNumber = 1,
    int pageSize = 10,
  }) async => ApiSuccess(pageOf(payoutAccounts));

  @override
  Future<ApiResult<PagedResult<ReviewReport>>> reviewReports({
    ReviewReportStatus? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) async => ApiSuccess(pageOf(reports));
}

class FakeAdminWithdrawalsApi extends AdminWithdrawalsApi {
  FakeAdminWithdrawalsApi({required this.withdrawal}) : super(Dio());

  WithdrawalRequest withdrawal;
  int approveCalls = 0;
  int markPaidCalls = 0;
  int retryCalls = 0;

  @override
  Future<ApiResult<PagedResult<WithdrawalRequest>>> list({
    WithdrawalStatus? status,
    bool pendingOnly = false,
    int pageNumber = 1,
    int pageSize = 10,
  }) async => ApiSuccess(pageOf([withdrawal]));

  @override
  Future<ApiResult<WithdrawalRequest>> detail(String id) async =>
      ApiSuccess(withdrawal);

  @override
  Future<ApiResult<WithdrawalRequest>> approve(String id) async {
    approveCalls++;
    return ApiSuccess(withdrawal);
  }

  @override
  Future<ApiResult<WithdrawalRequest>> markPaid(String id) async {
    markPaidCalls++;
    return ApiSuccess(withdrawal);
  }

  @override
  Future<ApiResult<WithdrawalRequest>> retryPayout(String id) async {
    retryCalls++;
    return ApiSuccess(withdrawal);
  }
}
