import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/training_plan.dart';
import '../data/training_plan_api.dart';
import 'training_plan_providers.dart';
import 'widgets/plan_item_sheets.dart';

/// One training plan per booking: coach authors the `weeks → days →
/// exercises` hierarchy; the learner follows it. Read-only once the plan is
/// terminal or the package expired.
class TrainingPlanScreen extends ConsumerWidget {
  const TrainingPlanScreen({
    super.key,
    required this.bookingId,
    required this.asCoach,
  });

  final String bookingId;
  final bool asCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(trainingPlanProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Giáo án luyện tập')),
      body: SafeArea(
        child: switch (plan) {
          AsyncData(:final value) =>
            value == null
                ? (asCoach
                      ? _CreatePlanForm(
                          bookingId: bookingId,
                          onCreated: () =>
                              ref.invalidate(trainingPlanProvider(bookingId)),
                        )
                      : const AppEmptyState(
                          icon: Icons.menu_book_outlined,
                          title: 'Chưa có giáo án',
                          message:
                              'Huấn luyện viên sẽ tạo giáo án dựa trên đánh giá '
                              'đầu vào của bạn.',
                        ))
                : _PlanView(
                    plan: value,
                    canEdit: asCoach && !value.isReadOnly,
                    onChanged: () =>
                        ref.invalidate(trainingPlanProvider(bookingId)),
                  ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () => ref.invalidate(trainingPlanProvider(bookingId)),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _PlanView extends ConsumerWidget {
  const _PlanView({
    required this.plan,
    required this.canEdit,
    required this.onChanged,
  });

  final TrainingPlan plan;
  final bool canEdit;
  final VoidCallback onChanged;

  AppBadgeTone get _tone => switch (plan.status) {
    PlanStatus.draft => AppBadgeTone.neutral,
    PlanStatus.active => AppBadgeTone.info,
    PlanStatus.completed => AppBadgeTone.success,
    PlanStatus.cancelled => AppBadgeTone.danger,
    PlanStatus.unknown => AppBadgeTone.neutral,
  };

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    PlanStatus next,
  ) async {
    final result = await ref
        .read(trainingPlanApiProvider)
        .updatePlan(
          plan.id,
          title: plan.title,
          goalType: plan.goalType,
          overview: plan.overview,
          startDate: plan.startDate ?? DateTime.now(),
          endDate: plan.endDate ?? DateTime.now(),
          totalWeeks: plan.totalWeeks,
          status: next.name,
        );
    if (!context.mounted) return;
    switch (result) {
      case ApiSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giáo án chuyển sang "${next.label}".')),
        );
        onChanged();
      case ApiFailure(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.xs,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(plan.title, style: AppTextStyles.sectionTitle),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppBadge(label: plan.status.label, tone: _tone),
                  if (canEdit && plan.status.nextStatuses.isNotEmpty)
                    SizedBox(
                      width: 32,
                      height: 24,
                      child: PopupMenuButton<PlanStatus>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onSelected: (next) => _changeStatus(context, ref, next),
                        itemBuilder: (context) => [
                          for (final next in plan.status.nextStatuses)
                            PopupMenuItem(
                              value: next,
                              child: Text('Chuyển sang: ${next.label}'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${PlanLabels.goal(plan.goalType)} · ${plan.totalWeeks} tuần · '
                '${DateFormatter.date(plan.startDate)} → ${DateFormatter.date(plan.endDate)}',
                style: AppTextStyles.bodySecondary,
              ),
              if (plan.overview?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(plan.overview!, style: AppTextStyles.body),
              ],
              if (plan.isReadOnly) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Giáo án ở chế độ chỉ đọc'
                    '${plan.readOnlyReason != null ? ' — ${plan.readOnlyReason}' : ''}.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Nội dung theo tuần',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: () async {
                  final added = await showAddWeekSheet(
                    context,
                    ref,
                    planId: plan.id,
                    suggestedNumber: plan.weeks.length + 1,
                  );
                  if (added) onChanged();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm tuần'),
              ),
          ],
        ),
        if (plan.weeks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              canEdit
                  ? 'Chưa có tuần nào. Thêm tuần đầu tiên để bắt đầu xây dựng '
                        'giáo án.'
                  : 'Giáo án đang được xây dựng.',
              style: AppTextStyles.bodySecondary,
            ),
          ),
        for (final week in plan.weeks) ...[
          const SizedBox(height: AppSpacing.xs),
          _WeekCard(week: week, canEdit: canEdit, onChanged: onChanged),
        ],
      ],
    );
  }
}

class _WeekCard extends ConsumerWidget {
  const _WeekCard({
    required this.week,
    required this.canEdit,
    required this.onChanged,
  });

  final PlanWeek week;
  final bool canEdit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          title: Text(
            'Tuần ${week.weekNumber}',
            style: AppTextStyles.cardTitle,
          ),
          subtitle: week.focus != null
              ? Text(
                  week.focus!,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          children: [
            if (week.notes?.isNotEmpty == true)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(week.notes!, style: AppTextStyles.bodySecondary),
                ),
              ),
            for (final day in week.days) ...[
              _DayBlock(day: day, canEdit: canEdit, onChanged: onChanged),
              const SizedBox(height: AppSpacing.xs),
            ],
            if (canEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final added = await showAddDaySheet(
                      context,
                      ref,
                      weekId: week.id,
                      suggestedNumber: week.days.length + 1,
                    );
                    if (added) onChanged();
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Thêm ngày tập'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayBlock extends ConsumerWidget {
  const _DayBlock({
    required this.day,
    required this.canEdit,
    required this.onChanged,
  });

  final PlanDay day;
  final bool canEdit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ngày ${day.dayNumber} · ${day.title}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (canEdit)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Thêm bài tập',
                  onPressed: () async {
                    final added = await showExerciseSheet(
                      context,
                      ref,
                      dayId: day.id,
                      suggestedOrder: day.exercises.length + 1,
                    );
                    if (added) onChanged();
                  },
                ),
            ],
          ),
          if (day.notes?.isNotEmpty == true)
            Text(day.notes!, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xxs),
          if (day.exercises.isEmpty)
            Text('Chưa có bài tập.', style: AppTextStyles.caption)
          else
            for (final exercise in day.exercises)
              _ExerciseRow(
                exercise: exercise,
                canEdit: canEdit,
                onChanged: onChanged,
              ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends ConsumerWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.canEdit,
    required this.onChanged,
  });

  final PlanExercise exercise;
  final bool canEdit;
  final VoidCallback onChanged;

  String get _specs {
    final parts = <String>[
      if (exercise.sets != null) '${exercise.sets} hiệp',
      if (exercise.reps != null) '${exercise.reps} lần',
      if (exercise.intensity != null) exercise.intensity!,
      if (exercise.restSeconds != null) 'nghỉ ${exercise.restSeconds}s',
    ];
    return parts.join(' · ');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài tập'),
        content: Text('Xóa "${exercise.exerciseName}" khỏi giáo án?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(trainingPlanApiProvider)
        .deleteExercise(exercise.id);
    if (!context.mounted) return;
    switch (result) {
      case ApiSuccess():
        onChanged();
      case ApiFailure(:final error):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(
              Icons.fitness_center_rounded,
              size: 13,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.exerciseName, style: AppTextStyles.body),
                if (_specs.isNotEmpty)
                  Text(_specs, style: AppTextStyles.caption),
                if (exercise.notes?.isNotEmpty == true)
                  Text(exercise.notes!, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (canEdit) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              onPressed: () async {
                final saved = await showExerciseSheet(
                  context,
                  ref,
                  dayId: null,
                  existing: exercise,
                  suggestedOrder: exercise.orderIndex,
                );
                if (saved) onChanged();
              },
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.danger,
              ),
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

/// Coach-only create form when no plan exists yet.
class _CreatePlanForm extends ConsumerStatefulWidget {
  const _CreatePlanForm({required this.bookingId, required this.onCreated});

  final String bookingId;
  final VoidCallback onCreated;

  @override
  ConsumerState<_CreatePlanForm> createState() => _CreatePlanFormState();
}

class _CreatePlanFormState extends ConsumerState<_CreatePlanForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _overview = TextEditingController();
  final _weeks = TextEditingController(text: '4');
  String? _goalType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _overview.dispose();
    _weeks.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_goalType == null) {
      setState(() => _error = 'Vui lòng chọn mục tiêu.');
      return;
    }
    if (_startDate == null || _endDate == null) {
      setState(() => _error = 'Vui lòng chọn ngày bắt đầu và kết thúc.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'Ngày kết thúc phải sau ngày bắt đầu.');
      return;
    }

    setState(() => _submitting = true);
    final result = await ref
        .read(trainingPlanApiProvider)
        .createPlan(
          widget.bookingId,
          title: _title.text.trim(),
          goalType: _goalType!,
          overview: _overview.text.trim().isEmpty
              ? null
              : _overview.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          totalWeeks: int.parse(_weeks.text.trim()),
        );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo giáo án (bản nháp).')),
        );
        widget.onCreated();
      case ApiFailure(:final error):
        setState(() {
          _submitting = false;
          _error = error.userMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.xs,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Chưa có giáo án cho đơn này. Tạo giáo án để định hướng lộ trình '
            'cho học viên.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Tên giáo án',
            controller: _title,
            hint: 'VD: Khối sức mạnh giai đoạn 1',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên.' : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Mục tiêu',
            style: AppTextStyles.bodySecondary.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final (key, label) in PlanLabels.goalOptions)
                ChoiceChip(
                  label: Text(label),
                  selected: _goalType == key,
                  onSelected: (_) => setState(() => _goalType = key),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Tổng quan (tùy chọn)',
            controller: _overview,
            hint: 'Định hướng chung của giáo án…',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _PlanDateField(
                  label: 'Bắt đầu',
                  value: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _PlanDateField(
                  label: 'Kết thúc',
                  value: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppTextField(
                  label: 'Số tuần',
                  controller: _weeks,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Từ 1 tuần.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                _error!,
                style: AppTextStyles.bodySecondary.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
          AppButton(
            label: 'Tạo giáo án',
            onPressed: _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }
}

class _PlanDateField extends StatelessWidget {
  const _PlanDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySecondary.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InputDecorator(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 14,
              ),
            ),
            child: Text(
              value == null ? 'Chọn' : DateFormatter.date(value),
              style: value == null
                  ? AppTextStyles.bodySecondary
                  : AppTextStyles.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
