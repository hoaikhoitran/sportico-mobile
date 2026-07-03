import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/learner_assessment.dart';
import 'models/progress_checkin.dart';
import 'models/training_plan.dart';

/// docs/api/personalized-training.md — assessment, plan hierarchy,
/// progress check-ins.
class TrainingPlanApi {
  TrainingPlanApi(this._dio);

  final Dio _dio;

  static LearnerAssessment _assessment(dynamic data) =>
      LearnerAssessment.fromJson(data as Map<String, dynamic>);

  static TrainingPlan _plan(dynamic data) =>
      TrainingPlan.fromJson(data as Map<String, dynamic>);

  static ProgressCheckIn _checkIn(dynamic data) =>
      ProgressCheckIn.fromJson(data as Map<String, dynamic>);

  // ---- Assessment ----

  Future<ApiResult<LearnerAssessment>> getAssessment(String bookingId) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.assessment(bookingId)),
      _assessment,
    );
  }

  Future<ApiResult<LearnerAssessment>> createAssessment(
    String bookingId,
    AssessmentDraft draft,
  ) {
    return safeApiCall(
      () => _dio.post(ApiEndpoints.assessment(bookingId), data: draft.toJson()),
      _assessment,
    );
  }

  Future<ApiResult<LearnerAssessment>> updateAssessment(
    String bookingId,
    AssessmentDraft draft,
  ) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.assessment(bookingId), data: draft.toJson()),
      _assessment,
    );
  }

  // ---- Training plan ----

  Future<ApiResult<TrainingPlan>> getPlan(String bookingId) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.trainingPlan(bookingId)),
      _plan,
    );
  }

  Future<ApiResult<TrainingPlan>> createPlan(
    String bookingId, {
    required String title,
    required String goalType,
    String? overview,
    required DateTime startDate,
    required DateTime endDate,
    required int totalWeeks,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.trainingPlan(bookingId),
        data: {
          'title': title,
          'goalType': goalType,
          'overview': ?overview,
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
          'totalWeeks': totalWeeks,
        },
      ),
      _plan,
    );
  }

  /// Header + status update (draft→active, active→completed/cancelled).
  Future<ApiResult<TrainingPlan>> updatePlan(
    String planId, {
    required String title,
    required String goalType,
    String? overview,
    required DateTime startDate,
    required DateTime endDate,
    required int totalWeeks,
    String? status,
  }) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.updateTrainingPlan(planId),
        data: {
          'title': title,
          'goalType': goalType,
          'overview': ?overview,
          'startDate': startDate.toUtc().toIso8601String(),
          'endDate': endDate.toUtc().toIso8601String(),
          'totalWeeks': totalWeeks,
          'status': ?status,
        },
      ),
      _plan,
    );
  }

  Future<ApiResult<void>> addWeek(
    String planId, {
    required int weekNumber,
    String? focus,
    String? notes,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.planWeeks(planId),
        data: {'weekNumber': weekNumber, 'focus': ?focus, 'notes': ?notes},
      ),
      (_) {},
    );
  }

  Future<ApiResult<void>> addDay(
    String weekId, {
    required int dayNumber,
    required String title,
    String? notes,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.weekDays(weekId),
        data: {'dayNumber': dayNumber, 'title': title, 'notes': ?notes},
      ),
      (_) {},
    );
  }

  Future<ApiResult<void>> addExercise(
    String dayId, {
    required String exerciseName,
    required int orderIndex,
    int? sets,
    String? reps,
    String? intensity,
    int? restSeconds,
    String? notes,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.dayExercises(dayId),
        data: {
          'exerciseName': exerciseName,
          'orderIndex': orderIndex,
          'sets': ?sets,
          'reps': ?reps,
          'intensity': ?intensity,
          'restSeconds': ?restSeconds,
          'notes': ?notes,
        },
      ),
      (_) {},
    );
  }

  Future<ApiResult<void>> updateExercise(
    String exerciseId, {
    required String exerciseName,
    required int orderIndex,
    int? sets,
    String? reps,
    String? intensity,
    int? restSeconds,
    String? notes,
  }) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.exercise(exerciseId),
        data: {
          'exerciseName': exerciseName,
          'orderIndex': orderIndex,
          'sets': ?sets,
          'reps': ?reps,
          'intensity': ?intensity,
          'restSeconds': ?restSeconds,
          'notes': ?notes,
        },
      ),
      (_) {},
    );
  }

  Future<ApiResult<void>> deleteExercise(String exerciseId) {
    return safeApiCall(
      () => _dio.delete(ApiEndpoints.exercise(exerciseId)),
      (_) {},
    );
  }

  // ---- Progress check-ins ----

  Future<ApiResult<PagedResult<ProgressCheckIn>>> checkIns(
    String bookingId, {
    int pageNumber = 1,
    int pageSize = 20,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.progressCheckIns(bookingId),
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        ProgressCheckIn.fromJson,
      ),
    );
  }

  Future<ApiResult<ProgressCheckIn>> createCheckIn(
    String bookingId, {
    required DateTime checkInDate,
    num? weightKg,
    num? bodyFatPercent,
    num? waistCm,
    String? energyLevel,
    String? sleepQuality,
    String? learnerNote,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.progressCheckIns(bookingId),
        data: {
          'checkInDate': checkInDate.toUtc().toIso8601String(),
          'weightKg': ?weightKg,
          'bodyFatPercent': ?bodyFatPercent,
          'waistCm': ?waistCm,
          'energyLevel': ?energyLevel,
          'sleepQuality': ?sleepQuality,
          'learnerNote': ?learnerNote,
        },
      ),
      _checkIn,
    );
  }

  Future<ApiResult<ProgressCheckIn>> giveCoachFeedback(
    String checkInId,
    String feedback,
  ) {
    return safeApiCall(
      () => _dio.put(
        ApiEndpoints.checkInFeedback(checkInId),
        data: {'coachFeedback': feedback},
      ),
      _checkIn,
    );
  }
}

final trainingPlanApiProvider = Provider<TrainingPlanApi>((ref) {
  return TrainingPlanApi(ref.watch(dioProvider));
});
