import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/public_coach.dart';

/// Public coach directory + coach reviews.
class CoachDirectoryApi {
  CoachDirectoryApi(this._dio);

  final Dio _dio;

  Future<ApiResult<PagedResult<PublicCoach>>> publicCoaches({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.publicCoaches,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'Keyword': keyword,
          'SportId': ?sportId,
          'PageNumber': pageNumber,
          'PageSize': pageSize,
        },
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        PublicCoach.fromJson,
      ),
    );
  }

  Future<ApiResult<PublicCoachDetail>> publicCoachDetail(String coachId) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.publicCoach(coachId)),
      (data) => PublicCoachDetail.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PagedResult<CoachReview>>> reviews(
    String coachId, {
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.coachReviews(coachId),
        queryParameters: {'PageNumber': pageNumber, 'PageSize': pageSize},
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        CoachReview.fromJson,
      ),
    );
  }

  Future<ApiResult<CoachReviewSummary>> reviewSummary(String coachId) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.coachReviewSummary(coachId)),
      (data) => CoachReviewSummary.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Learner posts a review (requires a booking with this coach).
  Future<ApiResult<CoachReview>> createReview(
    String coachId, {
    required int rating,
    String? comment,
    String? bookingId,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.coachReviews(coachId),
        data: {
          'coachId': coachId,
          'rating': rating,
          'comment': ?comment,
          'bookingId': ?bookingId,
        },
      ),
      (data) => CoachReview.fromJson(data as Map<String, dynamic>),
    );
  }
}

final coachDirectoryApiProvider = Provider<CoachDirectoryApi>((ref) {
  return CoachDirectoryApi(ref.watch(dioProvider));
});
