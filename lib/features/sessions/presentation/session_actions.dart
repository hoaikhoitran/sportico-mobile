import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/training_session.dart';
import '../data/training_session_repository.dart';

/// Session state transitions with their confirmation UIs.
/// Returns `true` when the action ran successfully (callers refresh lists).
class SessionActions {
  const SessionActions(this._ref);

  final WidgetRef _ref;

  /// Coach confirms a `requested` session (optional location/link/note).
  Future<bool> confirm(BuildContext context, TrainingSession session) async {
    final result = await showModalBottomSheet<_ConfirmData>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _ConfirmSheet(),
    );
    if (result == null || !context.mounted) return false;

    return _run(
      context,
      () => _ref
          .read(trainingSessionRepositoryProvider)
          .confirm(
            session.id,
            location: result.location,
            meetingUrl: result.meetingUrl,
            coachNote: result.note,
          ),
      successMessage: 'Đã xác nhận buổi tập.',
    );
  }

  /// Either participant cancels (optional reason).
  Future<bool> cancel(BuildContext context, TrainingSession session) async {
    final reason = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _CancelSheet(),
    );
    // Distinguish "sheet dismissed" (null) from "confirmed without reason" ('').
    if (reason == null || !context.mounted) return false;

    return _run(
      context,
      () => _ref
          .read(trainingSessionRepositoryProvider)
          .cancel(session.id, reason: reason.isEmpty ? null : reason),
      successMessage: 'Đã hủy buổi tập.',
    );
  }

  /// Coach completes a `scheduled` session — credits the wallet.
  Future<bool> complete(BuildContext context, TrainingSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn thành buổi tập'),
        content: const Text(
          'Xác nhận buổi tập đã diễn ra. Thu nhập của buổi này sẽ được cộng '
          'vào ví của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Chưa'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    return _run(
      context,
      () => _ref.read(trainingSessionRepositoryProvider).complete(session.id),
      successMessage: 'Buổi tập đã hoàn thành. Thu nhập đã vào ví.',
    );
  }

  Future<bool> _run(
    BuildContext context,
    Future<ApiResult<TrainingSession>> Function() action, {
    required String successMessage,
  }) async {
    final result = await action();
    if (!context.mounted) return result.isSuccess;
    final message = switch (result) {
      ApiSuccess() => successMessage,
      ApiFailure(:final ApiError error) => error.userMessage,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    return result.isSuccess;
  }
}

typedef _ConfirmData = ({String? location, String? meetingUrl, String? note});

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet();

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  final _location = TextEditingController();
  final _meetingUrl = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _location.dispose();
    _meetingUrl.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _valueOf(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : controller.text.trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Xác nhận buổi tập', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Các trường dưới đây là tùy chọn — bỏ trống nếu giữ nguyên.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Địa điểm',
            controller: _location,
            hint: 'VD: Phòng gym ABC',
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Link buổi tập online',
            controller: _meetingUrl,
            hint: 'https://meet…',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Ghi chú cho học viên',
            controller: _note,
            hint: 'VD: Mang giày thể thao',
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Xác nhận',
            onPressed: () => Navigator.of(context).pop((
              location: _valueOf(_location),
              meetingUrl: _valueOf(_meetingUrl),
              note: _valueOf(_note),
            )),
          ),
        ],
      ),
    );
  }
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hủy buổi tập', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bên còn lại sẽ nhận được thông báo về việc hủy buổi tập này.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Lý do (tùy chọn)',
            controller: _reason,
            hint: 'VD: Bận việc đột xuất',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Xác nhận hủy',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Không hủy',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }
}

/// Status badge tone shared by session UIs.
extension SessionStatusTone on SessionStatus {
  Color get toneColor => switch (this) {
    SessionStatus.requested => AppColors.warning,
    SessionStatus.scheduled => AppColors.info,
    SessionStatus.completed => AppColors.success,
    SessionStatus.cancelled => AppColors.danger,
    SessionStatus.missed => AppColors.textSecondary,
    SessionStatus.unknown => AppColors.textSecondary,
  };
}
