import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/paged_result.dart';
import 'models/training_package.dart';
import 'models/training_package_draft.dart';
import 'training_package_api.dart';

class TrainingPackageRepository {
  TrainingPackageRepository(this._api);

  final TrainingPackageApi _api;

  Future<ApiResult<PagedResult<TrainingPackage>>> publicList({
    String? keyword,
    int? sportId,
    int pageNumber = 1,
    int pageSize = 10,
  }) => _api.publicList(
    keyword: keyword,
    sportId: sportId,
    pageNumber: pageNumber,
    pageSize: pageSize,
  );

  Future<ApiResult<TrainingPackage>> publicDetail(String id) =>
      _api.publicDetail(id);

  Future<ApiResult<PagedResult<TrainingPackage>>> myList({
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) => _api.myList(status: status, pageNumber: pageNumber, pageSize: pageSize);

  Future<ApiResult<TrainingPackage>> myDetail(String id) => _api.myDetail(id);

  Future<ApiResult<TrainingPackage>> create(TrainingPackageDraft draft) =>
      _api.create(draft);

  Future<ApiResult<TrainingPackage>> update(
    String id,
    TrainingPackageDraft draft,
  ) => _api.update(id, draft);

  Future<ApiResult<TrainingPackage>> archive(String id) => _api.archive(id);
}

final trainingPackageRepositoryProvider = Provider<TrainingPackageRepository>((
  ref,
) {
  return TrainingPackageRepository(ref.watch(trainingPackageApiProvider));
});
