import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/paged_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../data/models/training_session.dart';
import '../data/training_session_repository.dart';

typedef ScheduleArgs = ({bool asCoach, bool upcoming});

/// Personal schedule (learner or coach view) split into upcoming and past.
class ScheduleController
    extends AsyncNotifier<PagedListState<TrainingSession>> {
  ScheduleController(this.args);

  final ScheduleArgs args;

  @override
  Future<PagedListState<TrainingSession>> build() =>
      _fetchPage(pageNumber: 1).then(PagedListState.fromFirstPage);

  Future<PagedResult<TrainingSession>> _fetchPage({
    required int pageNumber,
  }) async {
    final now = DateTime.now();
    final result = await ref
        .read(trainingSessionRepositoryProvider)
        .schedule(
          asCoach: args.asCoach,
          startFrom: args.upcoming ? now : null,
          startTo: args.upcoming ? null : now,
          pageNumber: pageNumber,
          pageSize: AppConfig.defaultPageSize,
        );
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => _fetchPage(pageNumber: 1).then(PagedListState.fromFirstPage),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    try {
      final page = await _fetchPage(pageNumber: current.pageNumber + 1);
      state = AsyncData(current.appendPage(page));
    } on Object {
      state = AsyncData(current.withLoadingMore(false));
    }
  }
}

final scheduleControllerProvider =
    AsyncNotifierProvider.family<
      ScheduleController,
      PagedListState<TrainingSession>,
      ScheduleArgs
    >(ScheduleController.new);
