import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../data/models/training_package.dart';
import '../data/training_package_repository.dart';

/// Public catalog list: keyword search + infinite scroll.
class PackageListController
    extends AsyncNotifier<PagedListState<TrainingPackage>> {
  String _keyword = '';

  @override
  Future<PagedListState<TrainingPackage>> build() => _fetchFirstPage();

  Future<PagedListState<TrainingPackage>> _fetchFirstPage() async {
    final result = await ref
        .read(trainingPackageRepositoryProvider)
        .publicList(keyword: _keyword, pageSize: AppConfig.defaultPageSize);
    return switch (result) {
      ApiSuccess(:final data) => PagedListState.fromFirstPage(data),
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> search(String keyword) async {
    _keyword = keyword.trim();
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
        .publicList(
          keyword: _keyword,
          pageNumber: current.pageNumber + 1,
          pageSize: AppConfig.defaultPageSize,
        );
    switch (result) {
      case ApiSuccess(:final data):
        state = AsyncData(current.appendPage(data));
      case ApiFailure():
        // Keep the loaded items; the user can scroll again to retry.
        state = AsyncData(current.withLoadingMore(false));
    }
  }
}

final packageListControllerProvider =
    AsyncNotifierProvider<
      PackageListController,
      PagedListState<TrainingPackage>
    >(PackageListController.new);

/// Public package detail.
final packageDetailProvider = FutureProvider.autoDispose
    .family<TrainingPackage, String>((ref, id) async {
      final result = await ref
          .watch(trainingPackageRepositoryProvider)
          .publicDetail(id);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) => throw error,
      };
    });
