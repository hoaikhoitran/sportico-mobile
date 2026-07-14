import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/paged_result.dart';
import 'models/admin_user.dart';

/// `/api/admin/users` — list, detail, create, update, deactivate.
class AdminUsersApi {
  AdminUsersApi(this._dio);

  final Dio _dio;

  Future<ApiResult<PagedResult<AdminUser>>> list({
    AdminUserFilter filter = const AdminUserFilter(),
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.adminUsers,
        queryParameters: {
          if (filter.search.isNotEmpty) 'Search': filter.search,
          'Role': ?filter.role,
          'Status': ?filter.status?.wireValue,
          'PageNumber': pageNumber,
          'PageSize': pageSize,
        },
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        AdminUser.fromJson,
      ),
    );
  }

  Future<ApiResult<AdminUser>> detail(String id) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.adminUser(id)),
      (data) => AdminUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<AdminUser>> create(AdminCreateUserRequest request) {
    return safeApiCall(
      () => _dio.post(ApiEndpoints.adminUsers, data: request.toJson()),
      (data) => AdminUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<AdminUser>> update(
    String id,
    AdminUpdateUserRequest request,
  ) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.adminUser(id), data: request.toJson()),
      (data) => AdminUser.fromJson(data as Map<String, dynamic>),
    );
  }

  /// `DELETE /api/admin/users/{id}` is a **deactivation**: the backend keeps
  /// the row and flips its status to `inactive` so bookings, reviews and
  /// wallet history stay intact. The UI must not promise a permanent delete.
  Future<ApiResult<AdminUser>> deactivate(String id) {
    return safeApiCall(
      () => _dio.delete(ApiEndpoints.adminUser(id)),
      (data) => AdminUser.fromJson(data as Map<String, dynamic>),
    );
  }
}

final adminUsersApiProvider = Provider<AdminUsersApi>((ref) {
  return AdminUsersApi(ref.watch(dioProvider));
});
