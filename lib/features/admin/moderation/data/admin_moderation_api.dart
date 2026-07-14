import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/paged_result.dart';
import '../../../training_packages/data/models/training_package.dart';
import '../../shared/models/admin_status.dart';
import 'models/admin_post.dart';
import 'models/coach_payout_account.dart';
import 'models/review_report.dart';

/// The four admin moderation queues.
///
/// `TrainingPackageResponse` is byte-for-byte the DTO the catalog already
/// parses, so the existing [TrainingPackage] model is reused instead of adding
/// a near-identical admin copy.
class AdminModerationApi {
  AdminModerationApi(this._dio);

  final Dio _dio;

  // ── Training packages ────────────────────────────────────────────────────
  /// `GET /api/admin/training-packages/pending`. The backend pins
  /// `Status = pending` server-side, so only keyword/sport are exposed here.
  Future<ApiResult<PagedResult<TrainingPackage>>> pendingPackages({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.adminPendingPackages,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'Keyword': keyword,
          'SportId': ?sportId,
          'PageNumber': pageNumber,
          'PageSize': pageSize,
        },
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        TrainingPackage.fromJson,
      ),
    );
  }

  Future<ApiResult<TrainingPackage>> approvePackage(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.adminApprovePackage(id)),
      (data) => TrainingPackage.fromJson(data as Map<String, dynamic>),
    );
  }

  /// `RejectTrainingPackageRequest.reason` is `NotEmpty` on the backend.
  Future<ApiResult<TrainingPackage>> rejectPackage(String id, String reason) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.adminRejectPackage(id),
        data: {'reason': reason},
      ),
      (data) => TrainingPackage.fromJson(data as Map<String, dynamic>),
    );
  }

  // ── Posts ────────────────────────────────────────────────────────────────
  /// `GET /api/admin/posts/pending` — returns `pending` **and** `draft` posts
  /// when no status is supplied.
  Future<ApiResult<PagedResult<AdminPost>>> pendingPosts({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.adminPendingPosts,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'Keyword': keyword,
          'SportId': ?sportId,
          'PageNumber': pageNumber,
          'PageSize': pageSize,
        },
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        AdminPost.fromJson,
      ),
    );
  }

  Future<ApiResult<AdminPost>> approvePost(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.adminApprovePost(id)),
      (data) => AdminPost.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<AdminPost>> rejectPost(String id, String reason) {
    return safeApiCall(
      () =>
          _dio.put(ApiEndpoints.adminRejectPost(id), data: {'reason': reason}),
      (data) => AdminPost.fromJson(data as Map<String, dynamic>),
    );
  }

  // ── Coach payout accounts ────────────────────────────────────────────────
  /// `GET /api/admin/coach-payout-accounts/pending`.
  /// Note the lower-case query names — this endpoint differs from the others.
  Future<ApiResult<PagedResult<CoachPayoutAccount>>> pendingPayoutAccounts({
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.adminPendingPayoutAccounts,
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        CoachPayoutAccount.fromJson,
      ),
    );
  }

  Future<ApiResult<CoachPayoutAccount>> verifyPayoutAccount(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.adminVerifyPayoutAccount(id)),
      (data) => CoachPayoutAccount.fromJson(data as Map<String, dynamic>),
    );
  }

  /// `RejectCoachPayoutAccountRequest.note` is optional on the backend.
  Future<ApiResult<CoachPayoutAccount>> rejectPayoutAccount(
    String id, {
    String? note,
  }) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.adminRejectPayoutAccount(id),
        data: {'note': ?note},
      ),
      (data) => CoachPayoutAccount.fromJson(data as Map<String, dynamic>),
    );
  }

  // ── Review reports ───────────────────────────────────────────────────────
  Future<ApiResult<PagedResult<ReviewReport>>> reviewReports({
    ReviewReportStatus? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.adminReviewReports,
        queryParameters: {
          'Status': ?status?.wireValue,
          'PageNumber': pageNumber,
          'PageSize': pageSize,
        },
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        ReviewReport.fromJson,
      ),
    );
  }

  Future<ApiResult<ReviewReport>> resolveReviewReport(
    String id,
    ResolveReviewReportRequest request,
  ) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.adminResolveReviewReport(id),
        data: request.toJson(),
      ),
      (data) => ReviewReport.fromJson(data as Map<String, dynamic>),
    );
  }
}

final adminModerationApiProvider = Provider<AdminModerationApi>((ref) {
  return AdminModerationApi(ref.watch(dioProvider));
});
