import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/training_session.dart';

/// docs/api/training-sessions.md.
///
/// The legacy learner request flow (`POST /api/bookings/{id}/sessions`) is
/// intentionally NOT implemented — fixed-schedule purchases auto-create all
/// sessions on the backend.
class TrainingSessionApi {
  TrainingSessionApi(this._dio);

  final Dio _dio;

  static PagedResult<TrainingSession> _paged(dynamic data) =>
      PagedResult.fromJson(
        data as Map<String, dynamic>,
        TrainingSession.fromJson,
      );

  static TrainingSession _single(dynamic data) =>
      TrainingSession.fromJson(data as Map<String, dynamic>);

  static Map<String, dynamic> _filterParams({
    String? status,
    DateTime? startFrom,
    DateTime? startTo,
    required int pageNumber,
    required int pageSize,
  }) => {
    'status': ?status,
    'startFrom': ?startFrom?.toUtc().toIso8601String(),
    'startTo': ?startTo?.toUtc().toIso8601String(),
    'pageNumber': pageNumber,
    'pageSize': pageSize,
  };

  /// Sessions of one booking (visible to both participants).
  Future<ApiResult<PagedResult<TrainingSession>>> byBooking(
    String bookingId, {
    String? status,
    int pageNumber = 1,
    int pageSize = 50,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.bookingSessions(bookingId),
        queryParameters: _filterParams(
          status: status,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      ),
      _paged,
    );
  }

  /// Learner schedule across all bookings.
  Future<ApiResult<PagedResult<TrainingSession>>> learnerSchedule({
    String? status,
    DateTime? startFrom,
    DateTime? startTo,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.learnerSessions,
        queryParameters: _filterParams(
          status: status,
          startFrom: startFrom,
          startTo: startTo,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      ),
      _paged,
    );
  }

  /// Coach schedule across all bookings.
  Future<ApiResult<PagedResult<TrainingSession>>> coachSchedule({
    String? status,
    DateTime? startFrom,
    DateTime? startTo,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.coachSessions,
        queryParameters: _filterParams(
          status: status,
          startFrom: startFrom,
          startTo: startTo,
          pageNumber: pageNumber,
          pageSize: pageSize,
        ),
      ),
      _paged,
    );
  }

  /// Coach: `requested → scheduled`.
  Future<ApiResult<TrainingSession>> confirm(
    String id, {
    String? location,
    String? meetingUrl,
    String? coachNote,
  }) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.confirmSession(id),
        data: {
          'location': ?location,
          'meetingUrl': ?meetingUrl,
          'coachNote': ?coachNote,
        },
      ),
      _single,
    );
  }

  /// Either participant: `requested|scheduled → cancelled`.
  Future<ApiResult<TrainingSession>> cancel(String id, {String? reason}) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.cancelSession(id), data: {'reason': ?reason}),
      _single,
    );
  }

  /// Coach: `scheduled → completed` — credits the coach wallet per session.
  Future<ApiResult<TrainingSession>> complete(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.completeSession(id)),
      _single,
    );
  }
}

final trainingSessionApiProvider = Provider<TrainingSessionApi>((ref) {
  return TrainingSessionApi(ref.watch(dioProvider));
});
