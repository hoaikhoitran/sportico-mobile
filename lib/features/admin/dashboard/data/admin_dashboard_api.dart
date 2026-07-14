import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import 'models/admin_dashboard.dart';

/// `GET /api/admin/dashboard`.
class AdminDashboardApi {
  AdminDashboardApi(this._dio);

  final Dio _dio;

  Future<ApiResult<AdminDashboard>> load(DashboardFilter filter) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.adminDashboard,
        queryParameters: filter.toQuery(),
      ),
      (data) => AdminDashboard.fromJson(data as Map<String, dynamic>),
    );
  }
}

final adminDashboardApiProvider = Provider<AdminDashboardApi>((ref) {
  return AdminDashboardApi(ref.watch(dioProvider));
});
