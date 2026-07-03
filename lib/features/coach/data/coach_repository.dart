import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import 'coach_api.dart';

class CoachRepository {
  CoachRepository(this._api);

  final CoachApi _api;

  Future<ApiResult<void>> register({
    required String headline,
    String? bio,
    int? experienceYears,
    required List<int> sportIds,
  }) => _api.register(
    headline: headline,
    bio: bio,
    experienceYears: experienceYears,
    sportIds: sportIds,
  );
}

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return CoachRepository(ref.watch(coachApiProvider));
});
