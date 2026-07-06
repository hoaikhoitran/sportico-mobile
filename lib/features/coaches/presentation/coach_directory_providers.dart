import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../data/coach_directory_api.dart';
import '../data/models/public_coach.dart';

/// Public coach directory: keyword search + infinite scroll.
class CoachListController extends AsyncNotifier<PagedListState<PublicCoach>> {
  String _keyword = '';

  @override
  Future<PagedListState<PublicCoach>> build() => _fetchFirstPage();

  Future<PagedListState<PublicCoach>> _fetchFirstPage() async {
    final result = await ref
        .read(coachDirectoryApiProvider)
        .publicCoaches(keyword: _keyword, pageSize: AppConfig.defaultPageSize);
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
        .read(coachDirectoryApiProvider)
        .publicCoaches(
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

final coachListControllerProvider =
    AsyncNotifierProvider<CoachListController, PagedListState<PublicCoach>>(
      CoachListController.new,
    );

/// Public coach profile.
final coachDetailProvider = FutureProvider.autoDispose
    .family<PublicCoachDetail, String>((ref, coachId) async {
      final result = await ref
          .watch(coachDirectoryApiProvider)
          .publicCoachDetail(coachId);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) => throw error,
      };
    });

/// Rating summary shown on the coach profile.
final coachReviewSummaryProvider = FutureProvider.autoDispose
    .family<CoachReviewSummary, String>((ref, coachId) async {
      final result = await ref
          .watch(coachDirectoryApiProvider)
          .reviewSummary(coachId);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) => throw error,
      };
    });

/// First page of reviews on the coach profile (full history is paged on
/// the backend; the profile shows the most recent ones).
final coachReviewsProvider = FutureProvider.autoDispose
    .family<PagedListState<CoachReview>, String>((ref, coachId) async {
      final result = await ref
          .watch(coachDirectoryApiProvider)
          .reviews(coachId, pageSize: AppConfig.defaultPageSize);
      return switch (result) {
        ApiSuccess(:final data) => PagedListState.fromFirstPage(data),
        ApiFailure(:final error) => throw error,
      };
    });
