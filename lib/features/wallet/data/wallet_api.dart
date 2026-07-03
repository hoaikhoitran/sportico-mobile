import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/coach_wallet.dart';

/// docs/api/wallet-withdrawals.md — READ-ONLY in phase 1.
/// `POST /api/coaches/me/withdrawal-requests` must NOT be called from mobile.
class WalletApi {
  WalletApi(this._dio);

  final Dio _dio;

  Future<ApiResult<CoachWallet>> wallet() {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.coachWallet),
      (data) => CoachWallet.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PagedResult<WalletTransaction>>> transactions({
    int pageNumber = 1,
    int pageSize = 20,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.coachWalletTransactions,
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        WalletTransaction.fromJson,
      ),
    );
  }
}

final walletApiProvider = Provider<WalletApi>((ref) {
  return WalletApi(ref.watch(dioProvider));
});
