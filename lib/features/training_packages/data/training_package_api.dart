import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/training_package.dart';
import 'models/training_package_draft.dart';

/// docs/api/training-packages.md — public catalog + coach CRUD.
/// Admin moderation endpoints are intentionally not implemented (phase 1).
class TrainingPackageApi {
  TrainingPackageApi(this._dio);

  final Dio _dio;

  static PagedResult<TrainingPackage> _paged(dynamic data) =>
      PagedResult.fromJson(
        data as Map<String, dynamic>,
        TrainingPackage.fromJson,
      );

  static TrainingPackage _single(dynamic data) =>
      TrainingPackage.fromJson(data as Map<String, dynamic>);

  Future<ApiResult<PagedResult<TrainingPackage>>> publicList({
    String? keyword,
    int? sportId,
    String? coachId,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.publicPackages,
        queryParameters: {
          if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
          'sportId': ?sportId,
          'coachId': ?coachId,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      ),
      _paged,
    );
  }

  Future<ApiResult<TrainingPackage>> publicDetail(String id) {
    return safeApiCall(() => _dio.get(ApiEndpoints.publicPackage(id)), _single);
  }

  Future<ApiResult<PagedResult<TrainingPackage>>> myList({
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.myPackages,
        queryParameters: {
          'status': ?status,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      ),
      _paged,
    );
  }

  Future<ApiResult<TrainingPackage>> myDetail(String id) {
    return safeApiCall(() => _dio.get(ApiEndpoints.myPackage(id)), _single);
  }

  Future<ApiResult<TrainingPackage>> create(TrainingPackageDraft draft) {
    return safeApiCall(
      () => _dio.post(ApiEndpoints.packages, data: draft.toJson()),
      _single,
    );
  }

  Future<ApiResult<TrainingPackage>> update(
    String id,
    TrainingPackageDraft draft,
  ) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.package(id), data: draft.toJson()),
      _single,
    );
  }

  Future<ApiResult<TrainingPackage>> archive(String id) {
    return safeApiCall(
      () => _dio.put(ApiEndpoints.archivePackage(id)),
      _single,
    );
  }
}

final trainingPackageApiProvider = Provider<TrainingPackageApi>((ref) {
  return TrainingPackageApi(ref.watch(dioProvider));
});
