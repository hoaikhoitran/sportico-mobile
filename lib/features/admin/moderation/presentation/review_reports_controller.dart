import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/presentation/admin_retry.dart';
import '../data/admin_moderation_api.dart';
import '../data/models/review_report.dart';

/// Reported reviews (`GET /api/admin/review-reports`), filterable by status.
class ReviewReportsController
    extends AsyncNotifier<PagedListState<ReviewReport>> {
  /// Defaults to the queue that needs work.
  ReviewReportStatus? _status = ReviewReportStatus.pending;

  ReviewReportStatus? get statusFilter => _status;
  bool get hasActiveFilters => _status != null;

  @override
  Future<PagedListState<ReviewReport>> build() => _fetchFirstPage();

  AdminModerationApi get _api => ref.read(adminModerationApiProvider);

  Future<PagedListState<ReviewReport>> _fetchFirstPage() async {
    final result = await _api.reviewReports(
      status: _status,
      pageSize: AppConfig.defaultPageSize,
    );
    return switch (result) {
      ApiSuccess(:final data) => PagedListState.fromFirstPage(data),
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> setStatus(ReviewReportStatus? status) async {
    _status = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> clearFilters() => setStatus(null);

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    final result = await _api.reviewReports(
      status: _status,
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

  /// Resolving changes the report's status (and possibly the review's), so the
  /// list is refetched to show the new state and counts.
  Future<ApiError?> resolve(String id, ResolveReviewReportRequest request) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('resolve-report', id),
          () => _api.resolveReviewReport(id, request),
          onSuccess: (_) => refresh(),
        );
  }

  /// No `GET /review-reports/{id}` on the admin API — the detail screen reads
  /// the report the list already loaded.
  ReviewReport? findById(String id) {
    final items = state.value?.items;
    if (items == null) return null;
    for (final report in items) {
      if (report.id == id) return report;
    }
    return null;
  }
}

final reviewReportsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      ReviewReportsController,
      PagedListState<ReviewReport>
    >(ReviewReportsController.new, retry: adminNoRetry);
