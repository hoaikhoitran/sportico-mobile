import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../../training_packages/data/models/training_package.dart';
import '../../training_packages/data/training_package_repository.dart';

/// Coach's own packages (`GET /api/training-packages/me`), filterable by
/// status, with infinite scroll and archive.
class CoachPackagesController
    extends AsyncNotifier<PagedListState<TrainingPackage>> {
  PackageStatus? _statusFilter;

  PackageStatus? get statusFilter => _statusFilter;

  @override
  Future<PagedListState<TrainingPackage>> build() => _fetchFirstPage();

  String? get _statusParam => switch (_statusFilter) {
    null || PackageStatus.unknown => null,
    final s => s.name,
  };

  Future<PagedListState<TrainingPackage>> _fetchFirstPage() async {
    final result = await ref
        .read(trainingPackageRepositoryProvider)
        .myList(status: _statusParam, pageSize: AppConfig.defaultPageSize);
    return switch (result) {
      ApiSuccess(:final data) => PagedListState.fromFirstPage(data),
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> setFilter(PackageStatus? status) async {
    _statusFilter = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    final result = await ref
        .read(trainingPackageRepositoryProvider)
        .myList(
          status: _statusParam,
          pageNumber: current.pageNumber + 1,
          pageSize: AppConfig.defaultPageSize,
        );
    switch (result) {
      case ApiSuccess(:final data):
        state = AsyncData(current.appendPage(data));
      case ApiFailure():
        state = AsyncData(current.withLoadingMore(false));
    }
  }

  /// Archives and refreshes in place. Returns the error to show, if any.
  Future<ApiError?> archive(String id) async {
    final result = await ref
        .read(trainingPackageRepositoryProvider)
        .archive(id);
    switch (result) {
      case ApiSuccess():
        await refresh();
        return null;
      case ApiFailure(:final error):
        return error;
    }
  }
}

final coachPackagesControllerProvider =
    AsyncNotifierProvider<
      CoachPackagesController,
      PagedListState<TrainingPackage>
    >(CoachPackagesController.new);

/// One of the coach's own packages (edit prefill).
final coachPackageDetailProvider = FutureProvider.autoDispose
    .family<TrainingPackage, String>((ref, id) async {
      final result = await ref
          .watch(trainingPackageRepositoryProvider)
          .myDetail(id);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) => throw error,
      };
    });
