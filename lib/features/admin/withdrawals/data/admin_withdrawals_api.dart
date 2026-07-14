import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/paged_result.dart';
import '../../shared/models/admin_status.dart';
import 'models/withdrawal_request.dart';

/// `/api/admin/withdrawal-requests` — review and process coach payouts.
class AdminWithdrawalsApi {
  AdminWithdrawalsApi(this._dio);

  final Dio _dio;

  /// [pendingOnly] switches to the `/pending` shortcut endpoint.
  ///
  /// The backend rejects a status it does not know with a 400, so only the
  /// enum's own wire values are ever sent.
  Future<ApiResult<PagedResult<WithdrawalRequest>>> list({
    WithdrawalStatus? status,
    bool pendingOnly = false,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        pendingOnly
            ? ApiEndpoints.adminPendingWithdrawals
            : ApiEndpoints.adminWithdrawals,
        queryParameters: {
          'Status': ?status?.wireValue,
          'PageNumber': pageNumber,
          'PageSize': pageSize,
        },
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        WithdrawalRequest.fromJson,
      ),
    );
  }

  Future<ApiResult<WithdrawalRequest>> detail(String id) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.adminWithdrawal(id)),
      (data) => WithdrawalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<WithdrawalRequest>> approve(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.adminApproveWithdrawal(id)),
      (data) => WithdrawalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  /// `RejectWithdrawalRequest.adminNote` is optional on the backend.
  Future<ApiResult<WithdrawalRequest>> reject(String id, {String? adminNote}) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.adminRejectWithdrawal(id),
        data: {'adminNote': ?adminNote},
      ),
      (data) => WithdrawalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<WithdrawalRequest>> markPaid(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.adminMarkWithdrawalPaid(id)),
      (data) => WithdrawalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Re-reads the payout state from PayOS and reconciles the withdrawal.
  Future<ApiResult<WithdrawalRequest>> refreshPayoutStatus(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.adminRefreshPayoutStatus(id)),
      (data) => WithdrawalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Only a `failed` withdrawal can be retried.
  Future<ApiResult<WithdrawalRequest>> retryPayout(String id) {
    return safeApiCall(
      () => _dio.post(ApiEndpoints.adminRetryPayout(id)),
      (data) => WithdrawalRequest.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<WithdrawalReceipt>> receipt(String id) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.adminWithdrawalReceipt(id)),
      (data) => WithdrawalReceipt.fromJson(data as Map<String, dynamic>),
    );
  }
}

final adminWithdrawalsApiProvider = Provider<AdminWithdrawalsApi>((ref) {
  return AdminWithdrawalsApi(ref.watch(dioProvider));
});
