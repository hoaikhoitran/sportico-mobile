import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../../training_packages/data/models/training_package.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/presentation/admin_retry.dart';
import '../data/admin_moderation_api.dart';

/// Packages awaiting approval (`GET /api/admin/training-packages/pending`).
class PendingPackagesController
    extends AsyncNotifier<PagedListState<TrainingPackage>> {
  String _keyword = '';

  String get keyword => _keyword;
  bool get hasActiveFilters => _keyword.isNotEmpty;

  @override
  Future<PagedListState<TrainingPackage>> build() => _fetchFirstPage();

  AdminModerationApi get _api => ref.read(adminModerationApiProvider);

  Future<PagedListState<TrainingPackage>> _fetchFirstPage() async {
    final result = await _api.pendingPackages(
      keyword: _keyword,
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

  Future<void> clearFilters() => search('');

  /// Refreshes from page 1 while keeping the active keyword.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    final result = await _api.pendingPackages(
      keyword: _keyword,
      pageNumber: current.pageNumber + 1,
      pageSize: AppConfig.defaultPageSize,
    );
    switch (result) {
      case ApiSuccess(:final data):
        state = AsyncData(current.appendPage(data));
      case ApiFailure():
        // Keep what is already on screen; scrolling again retries.
        state = AsyncData(current.withLoadingMore(false));
    }
  }

  /// Approving removes the package from this queue → refresh page 1.
  Future<ApiError?> approve(String id) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('approve-package', id),
          () => _api.approvePackage(id),
          onSuccess: (_) => refresh(),
        );
  }

  Future<ApiError?> reject(String id, String reason) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('reject-package', id),
          () => _api.rejectPackage(id, reason),
          onSuccess: (_) => refresh(),
        );
  }

  /// The admin API has no `GET /training-packages/{id}` — the detail screen
  /// reads the package the list already loaded.
  TrainingPackage? findById(String id) {
    final items = state.value?.items;
    if (items == null) return null;
    for (final package in items) {
      if (package.id == id) return package;
    }
    return null;
  }
}

final pendingPackagesControllerProvider =
    AsyncNotifierProvider.autoDispose<
      PendingPackagesController,
      PagedListState<TrainingPackage>
    >(PendingPackagesController.new, retry: adminNoRetry);
