import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../data/models/training_package.dart';
import '../data/training_package_repository.dart';

/// Public catalog list: keyword search + sport filter + infinite scroll.
class PackageListController
    extends AsyncNotifier<PagedListState<TrainingPackage>> {
  String _keyword = '';
  int? _sportId;

  /// Whether a keyword or sport filter is currently applied — used by the
  /// screen to offer a "clear filters" action on empty results.
  bool get hasFilter => _keyword.isNotEmpty || _sportId != null;

  int? get sportId => _sportId;

  @override
  Future<PagedListState<TrainingPackage>> build() => _fetchFirstPage();

  Future<PagedListState<TrainingPackage>> _fetchFirstPage() async {
    final result = await ref
        .read(trainingPackageRepositoryProvider)
        .publicList(
          keyword: _keyword,
          sportId: _sportId,
          pageSize: AppConfig.defaultPageSize,
        );
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

  Future<void> setSport(int? sportId) async {
    if (_sportId == sportId) return;
    _sportId = sportId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> clearFilters() async {
    _keyword = '';
    _sportId = null;
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
          sportId: _sportId,
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
