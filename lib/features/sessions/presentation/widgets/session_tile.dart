import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/training_session.dart';

/// One training session row with role-aware actions.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    this.index,
    this.isCoach = false,
    this.onConfirm,
    this.onCancel,
    this.onComplete,
    this.onTap,
  });

  final TrainingSession session;

  /// 1-based session order when shown inside a booking.
  final int? index;

  final bool isCoach;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  AppBadgeTone get _tone => switch (session.status) {
    SessionStatus.requested => AppBadgeTone.warning,
    SessionStatus.scheduled => AppBadgeTone.info,
    SessionStatus.completed => AppBadgeTone.success,
    SessionStatus.cancelled => AppBadgeTone.danger,
    SessionStatus.missed => AppBadgeTone.neutral,
    SessionStatus.unknown => AppBadgeTone.neutral,
  };

  /// Soft leading accent that lets the reader scan a session's status before
  /// reading the badge. Reuses the badge's own tone colors — no new palette.
  Color get _accent => switch (session.status) {
    SessionStatus.requested => AppColors.warningSoft,
    SessionStatus.scheduled => AppColors.infoSoft,
    SessionStatus.completed => AppColors.successSoft,
    SessionStatus.cancelled => AppColors.dangerSoft,
    SessionStatus.missed => AppColors.surfaceContainerHighest,
    SessionStatus.unknown => AppColors.surfaceContainerHighest,
  };

  bool get _coachCanConfirm =>
      isCoach && session.status == SessionStatus.requested && onConfirm != null;

  bool get _coachCanComplete =>
      isCoach &&
      session.status == SessionStatus.scheduled &&
      onComplete != null;

  bool get _canCancel =>
      (session.status == SessionStatus.requested ||
          session.status == SessionStatus.scheduled) &&
      onCancel != null;

  @override
  Widget build(BuildContext context) {
    final hasActions = _coachCanConfirm || _coachCanComplete || _canCancel;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 4, color: _accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accentBlueSoft,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: index != null
                            ? Text(
                                '$index',
                                style: AppTextStyles.cardTitle.copyWith(
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.fitness_center_rounded,
                                size: 19,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormatter.weekdayDate(session.startTime),
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              DateFormatter.timeRange(
                                session.startTime,
                                session.endTime,
                              ),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      AppBadge(label: session.status.label, tone: _tone),
                    ],
                  ),
                  if (session.location != null ||
                      session.meetingUrl != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          session.meetingUrl != null
                              ? Icons.videocam_outlined
                              : Icons.place_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            session.meetingUrl ?? session.location!,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (session.coachNote != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'HLV: ${session.coachNote}',
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasActions) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_canCancel)
                          TextButton(
                            onPressed: onCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              visualDensity: VisualDensity.compact,
                              textStyle: AppTextStyles.button.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            child: const Text('Hủy buổi'),
                          ),
                        if (_coachCanConfirm) ...[
                          const SizedBox(width: AppSpacing.xs),
                          FilledButton(
                            onPressed: onConfirm,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              textStyle: AppTextStyles.button.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            child: const Text('Xác nhận'),
                          ),
                        ],
                        if (_coachCanComplete) ...[
                          const SizedBox(width: AppSpacing.xs),
                          FilledButton(
                            onPressed: onComplete,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              textStyle: AppTextStyles.button.copyWith(
                                fontSize: 13,
                              ),
                            ),
                            child: const Text('Hoàn thành'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
