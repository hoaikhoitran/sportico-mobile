import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/app_notification.dart';

/// docs/api/notifications.md — list, unread badge, mark read.
class NotificationApi {
  NotificationApi(this._dio);

  final Dio _dio;

  Future<ApiResult<PagedResult<AppNotification>>> list({
    int pageNumber = 1,
    int pageSize = 20,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        AppNotification.fromJson,
      ),
    );
  }

  Future<ApiResult<int>> unreadCount() {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.unreadCount),
      (data) => (data as num?)?.toInt() ?? 0,
    );
  }

  Future<ApiResult<void>> markRead(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.markNotificationRead(id)),
      (_) {},
    );
  }

  Future<ApiResult<void>> markAllRead() {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.markAllNotificationsRead),
      (_) {},
    );
  }
}

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(dioProvider));
});
