import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/presentation/admin_retry.dart';
import '../data/admin_moderation_api.dart';
import '../data/models/admin_post.dart';

/// Posts awaiting moderation (`GET /api/admin/posts/pending` — the backend
/// returns both `pending` and `draft` posts).
class PendingPostsController extends AsyncNotifier<PagedListState<AdminPost>> {
  String _keyword = '';

  String get keyword => _keyword;
  bool get hasActiveFilters => _keyword.isNotEmpty;

  @override
  Future<PagedListState<AdminPost>> build() => _fetchFirstPage();

  AdminModerationApi get _api => ref.read(adminModerationApiProvider);

  Future<PagedListState<AdminPost>> _fetchFirstPage() async {
    final result = await _api.pendingPosts(
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

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    final result = await _api.pendingPosts(
      keyword: _keyword,
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

  Future<ApiError?> approve(String id) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('approve-post', id),
          () => _api.approvePost(id),
          onSuccess: (_) => refresh(),
        );
  }

  Future<ApiError?> reject(String id, String reason) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('reject-post', id),
          () => _api.rejectPost(id, reason),
          onSuccess: (_) => refresh(),
        );
  }

  /// No `GET /posts/{id}` on the admin API — the detail screen reads the post
  /// the list already loaded.
  AdminPost? findById(String id) {
    final items = state.value?.items;
    if (items == null) return null;
    for (final post in items) {
      if (post.id == id) return post;
    }
    return null;
  }
}

final pendingPostsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      PendingPostsController,
      PagedListState<AdminPost>
    >(PendingPostsController.new, retry: adminNoRetry);
