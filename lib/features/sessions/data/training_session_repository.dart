import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/paged_result.dart';
import 'models/training_session.dart';
import 'training_session_api.dart';

class TrainingSessionRepository {
  TrainingSessionRepository(this._api);

  final TrainingSessionApi _api;

  Future<ApiResult<PagedResult<TrainingSession>>> byBooking(
    String bookingId, {
    int pageNumber = 1,
    int pageSize = 50,
  }) => _api.byBooking(bookingId, pageNumber: pageNumber, pageSize: pageSize);

  Future<ApiResult<PagedResult<TrainingSession>>> schedule({
    required bool asCoach,
    String? status,
    DateTime? startFrom,
    DateTime? startTo,
    int pageNumber = 1,
    int pageSize = 10,
  }) => asCoach
      ? _api.coachSchedule(
          status: status,
          startFrom: startFrom,
          startTo: startTo,
          pageNumber: pageNumber,
          pageSize: pageSize,
        )
      : _api.learnerSchedule(
          status: status,
          startFrom: startFrom,
          startTo: startTo,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );

  Future<ApiResult<TrainingSession>> confirm(
    String id, {
    String? location,
    String? meetingUrl,
    String? coachNote,
  }) => _api.confirm(
    id,
    location: location,
    meetingUrl: meetingUrl,
    coachNote: coachNote,
  );

  Future<ApiResult<TrainingSession>> cancel(String id, {String? reason}) =>
      _api.cancel(id, reason: reason);

  Future<ApiResult<TrainingSession>> complete(String id) => _api.complete(id);
}

final trainingSessionRepositoryProvider = Provider<TrainingSessionRepository>((
  ref,
) {
  return TrainingSessionRepository(ref.watch(trainingSessionApiProvider));
});
