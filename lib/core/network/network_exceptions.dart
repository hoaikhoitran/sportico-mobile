import 'package:dio/dio.dart';

import 'api_error.dart';
import 'api_result.dart';

/// Maps a [DioException] to an [ApiError].
///
/// Non-2xx responses still carry the backend envelope, so the `error` node is
/// parsed when present; transport-level failures get Vietnamese copy.
ApiError mapDioException(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final error = data['error'];
    if (error is Map<String, dynamic>) return ApiError.fromJson(error);
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return ApiError.unknown(message);
    }
  }

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => ApiError.network(
      'Kết nối tới máy chủ quá lâu. Vui lòng thử lại.',
    ),
    DioExceptionType.connectionError => ApiError.network(
      'Không thể kết nối tới máy chủ. Kiểm tra mạng của bạn.',
    ),
    DioExceptionType.cancel => ApiError.network('Yêu cầu đã bị hủy.'),
    _ => ApiError.unknown(),
  };
}

/// Runs [request] and parses the generic `Result<T>` envelope.
Future<ApiResult<T>> safeApiCall<T>(
  Future<Response<dynamic>> Function() request,
  T Function(dynamic data) fromData,
) async {
  try {
    final response = await request();
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return ApiResult.fromEnvelope(body, fromData);
    }
    return ApiFailure(ApiError.unknown());
  } on DioException catch (e) {
    return ApiFailure(mapDioException(e));
  } on FormatException {
    return ApiFailure(ApiError.unknown('Dữ liệu trả về không hợp lệ.'));
  }
}

/// Runs [request] and parses the non-generic `{ isSuccess, message }` envelope
/// (register / verify-email).
Future<ApiResult<String>> safeMessageCall(
  Future<Response<dynamic>> Function() request,
) async {
  try {
    final response = await request();
    final body = response.data;
    if (body is Map<String, dynamic>) {
      return ApiResult.fromMessageEnvelope(body);
    }
    return ApiFailure(ApiError.unknown());
  } on DioException catch (e) {
    return ApiFailure(mapDioException(e));
  }
}
