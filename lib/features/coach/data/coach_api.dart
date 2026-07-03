import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';

/// `POST /api/coaches/register` — grants the `coach` role and creates the
/// coach profile (docs/api/auth.md).
class CoachApi {
  CoachApi(this._dio);

  final Dio _dio;

  Future<ApiResult<void>> register({
    required String headline,
    String? bio,
    int? experienceYears,
    required List<int> sportIds,
  }) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.coachRegister,
        data: {
          'headline': headline,
          'bio': ?bio,
          'experienceYears': ?experienceYears,
          'sportIds': sportIds,
        },
      ),
      (_) {},
    );
  }
}

final coachApiProvider = Provider<CoachApi>((ref) {
  return CoachApi(ref.watch(dioProvider));
});
