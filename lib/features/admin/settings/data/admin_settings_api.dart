import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import 'models/platform_commission.dart';

/// `/api/admin/platform-settings/commission`.
class AdminSettingsApi {
  AdminSettingsApi(this._dio);

  final Dio _dio;

  Future<ApiResult<PlatformCommission>> commission() {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.adminCommission),
      (data) => PlatformCommission.fromJson(data as Map<String, dynamic>),
    );
  }

  /// [commissionPercent] is a percent value in 0–100 (see [PlatformCommission]).
  Future<ApiResult<PlatformCommission>> updateCommission(
    num commissionPercent,
  ) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.adminCommission,
        data: {'commissionPercent': commissionPercent},
      ),
      (data) => PlatformCommission.fromJson(data as Map<String, dynamic>),
    );
  }
}

final adminSettingsApiProvider = Provider<AdminSettingsApi>((ref) {
  return AdminSettingsApi(ref.watch(dioProvider));
});
