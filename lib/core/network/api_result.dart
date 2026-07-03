import 'api_error.dart';

/// Typed outcome of every backend call.
///
/// Mirrors the backend envelope
/// `{ "isSuccess": ..., "data": ..., "error": ... }` — a `200` body with
/// `isSuccess: false` is treated as a failure.
sealed class ApiResult<T> {
  const ApiResult();

  bool get isSuccess => this is ApiSuccess<T>;

  T get requireData => (this as ApiSuccess<T>).data;
  ApiError get requireError => (this as ApiFailure<T>).error;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiError error) failure,
  }) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiFailure<T>(:final error) => failure(error),
    };
  }

  /// Parses the generic envelope. [fromData] converts the raw `data` node.
  static ApiResult<T> fromEnvelope<T>(
    Map<String, dynamic> json,
    T Function(dynamic data) fromData,
  ) {
    if (json['isSuccess'] == true) {
      return ApiSuccess(fromData(json['data']));
    }
    final error = json['error'];
    return ApiFailure(
      error is Map<String, dynamic>
          ? ApiError.fromJson(error)
          : ApiError.unknown(json['message'] as String?),
    );
  }

  /// Parses the non-generic envelope used by register / verify-email:
  /// `{ "isSuccess": true, "message": "..." }`.
  static ApiResult<String> fromMessageEnvelope(Map<String, dynamic> json) {
    if (json['isSuccess'] == true) {
      return ApiSuccess(json['message'] as String? ?? '');
    }
    final error = json['error'];
    return ApiFailure(
      error is Map<String, dynamic>
          ? ApiError.fromJson(error)
          : ApiError.unknown(json['message'] as String?),
    );
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;
}

final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);
  final ApiError error;
}
