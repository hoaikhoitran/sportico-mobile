import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/paged_list_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/training_session.dart';
import 'schedule_controller.dart';
import 'session_actions.dart';
import 'widgets/session_tile.dart';

/// Schedule tab. Users holding both roles can switch between their learner
/// schedule and their coaching schedule.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _scrollController = ScrollController();
  bool _coachView = false;
  bool _upcoming = true;

  /// The provider args currently on screen — set in build, because the
  /// effective role can differ from the toggle (single-role accounts).
  ScheduleArgs _activeArgs = (asCoach: false, upcoming: true);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        ref.read(scheduleControllerProvider(_activeArgs).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(scheduleControllerProvider(_activeArgs));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    // Single-role accounts get their only valid view.
    final showRoleSwitch = auth.isCoach && auth.isLearner;
    final effectiveCoachView = auth.isCoach && (_coachView || !auth.isLearner);

    _activeArgs = (asCoach: effectiveCoachView, upcoming: _upcoming);
    final listState = ref.watch(scheduleControllerProvider(_activeArgs));
    final actions = SessionActions(ref);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch tập'),
        actions: [
          if (showRoleSwitch)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.screenH),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Học viên')),
                  ButtonSegment(value: true, label: Text('HLV')),
                ],
                selected: {_coachView},
                onSelectionChanged: (selection) =>
                    setState(() => _coachView = selection.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: AppTextStyles.caption,
                ),
                showSelectedIcon: false,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
                vertical: AppSpacing.xs,
              ),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Sắp tới')),
                    ButtonSegment(value: false, label: Text('Đã qua')),
                  ],
                  selected: {_upcoming},
                  onSelectionChanged: (selection) =>
                      setState(() => _upcoming = selection.first),
                  showSelectedIcon: false,
                ),
              ),
            ),
            Expanded(
              child: switch (listState) {
                AsyncData(:final value) =>
                  value.isEmpty
                      ? AppEmptyState(
                          icon: Icons.calendar_month_rounded,
                          title: _upcoming
                              ? 'Chưa có buổi tập sắp tới'
                              : 'Chưa có buổi tập nào đã qua',
                          message: _upcoming
                              ? (effectiveCoachView
                                    ? 'Các buổi dạy sẽ xuất hiện khi học viên '
                                          'đăng ký gói tập của bạn.'
                                    : 'Đăng ký một gói tập để bắt đầu — lịch tập '
                                          'sẽ được tạo tự động.')
                              : 'Lịch sử buổi tập của bạn sẽ hiển thị ở đây.',
                          actionLabel: _upcoming && !effectiveCoachView
                              ? 'Khám phá gói tập'
                              : null,
                          onAction: _upcoming && !effectiveCoachView
                              ? () => context.go(RouteNames.packages)
                              : null,
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _refreshAll(),
                          child: _GroupedSessionList(
                            scrollController: _scrollController,
                            state: value,
                            upcoming: _upcoming,
                            isCoach: effectiveCoachView,
                            onOpenBooking: (session) => context.push(
                              effectiveCoachView
                                  ? RouteNames.coachBookingDetailPath(
                                      session.bookingId,
                                    )
                                  : RouteNames.bookingDetailPath(
                                      session.bookingId,
                                    ),
                            ),
                            onConfirm: (session) async {
                              if (await actions.confirm(context, session)) {
                                _refreshAll();
                              }
                            },
                            onCancel: (session) async {
                              if (await actions.cancel(context, session)) {
                                _refreshAll();
                              }
                            },
                            onComplete: (session) async {
                              if (await actions.complete(context, session)) {
                                _refreshAll();
                              }
                            },
                          ),
                        ),
                AsyncError(:final error) => AppErrorState(
                  error: error is ApiError ? error : null,
                  onRetry: _refreshAll,
                ),
                _ => const AppSkeletonList(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedSessionList extends StatelessWidget {
  const _GroupedSessionList({
    required this.scrollController,
    required this.state,
    required this.upcoming,
    required this.isCoach,
    required this.onOpenBooking,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
  });

  final ScrollController scrollController;
  final PagedListState<TrainingSession> state;
  final bool upcoming;
  final bool isCoach;
  final void Function(TrainingSession) onOpenBooking;
  final void Function(TrainingSession) onConfirm;
  final void Function(TrainingSession) onCancel;
  final void Function(TrainingSession) onComplete;

  @override
  Widget build(BuildContext context) {
    final sessions = [...state.items]
      ..sort((a, b) {
        final at = a.startTime, bt = b.startTime;
        if (at == null || bt == null) return 0;
        return upcoming ? at.compareTo(bt) : bt.compareTo(at);
      });

    // Flatten into date headers + tiles.
    final rows = <Widget>[];
    DateTime? currentDay;
    for (final session in sessions) {
      final start = session.startTime;
      final day = start == null
          ? null
          : DateTime(start.year, start.month, start.day);
      if (day != null && day != currentDay) {
        currentDay = day;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              DateFormatter.weekdayDate(start).toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.accentBlue,
              ),
            ),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: SessionTile(
            session: session,
            isCoach: isCoach,
            onTap: () => onOpenBooking(session),
            onConfirm: () => onConfirm(session),
            onCancel: () => onCancel(session),
            onComplete: () => onComplete(session),
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        ...rows,
        if (state.hasNext)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
