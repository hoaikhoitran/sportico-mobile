import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/training_plan.dart';
import '../../data/training_plan_api.dart';

/// Bottom-sheet forms for the plan hierarchy. Each returns `true` when the
/// backend accepted the mutation (callers then refresh the plan).

Future<bool> showAddWeekSheet(
  BuildContext context,
  WidgetRef ref, {
  required String planId,
  required int suggestedNumber,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) =>
        _AddWeekSheet(planId: planId, suggestedNumber: suggestedNumber),
  );
  return result == true;
}

Future<bool> showAddDaySheet(
  BuildContext context,
  WidgetRef ref, {
  required String weekId,
  required int suggestedNumber,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) =>
        _AddDaySheet(weekId: weekId, suggestedNumber: suggestedNumber),
  );
  return result == true;
}

/// Create (pass [dayId]) or edit (pass [existing]) an exercise.
Future<bool> showExerciseSheet(
  BuildContext context,
  WidgetRef ref, {
  required String? dayId,
  PlanExercise? existing,
  required int suggestedOrder,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _ExerciseSheet(
      dayId: dayId,
      existing: existing,
      suggestedOrder: suggestedOrder,
    ),
  );
  return result == true;
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AddWeekSheet extends ConsumerStatefulWidget {
  const _AddWeekSheet({required this.planId, required this.suggestedNumber});

  final String planId;
  final int suggestedNumber;

  @override
  ConsumerState<_AddWeekSheet> createState() => _AddWeekSheetState();
}

class _AddWeekSheetState extends ConsumerState<_AddWeekSheet> {
  late final _number = TextEditingController(
    text: widget.suggestedNumber.toString(),
  );
  final _focus = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _number.dispose();
    _focus.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final number = int.tryParse(_number.text.trim());
    if (number == null || number < 1) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(trainingPlanApiProvider)
        .addWeek(
          widget.planId,
          weekNumber: number,
          focus: _focus.text.trim().isEmpty ? null : _focus.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() => _submitting = false);
        AppSnackBar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Thêm tuần',
      children: [
        AppTextField(
          label: 'Tuần số',
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Trọng tâm (tùy chọn)',
          controller: _focus,
          hint: 'VD: Thân dưới',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Ghi chú (tùy chọn)',
          controller: _notes,
          hint: 'VD: RPE 6–7',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Thêm', onPressed: _submit, loading: _submitting),
      ],
    );
  }
}

class _AddDaySheet extends ConsumerStatefulWidget {
  const _AddDaySheet({required this.weekId, required this.suggestedNumber});

  final String weekId;
  final int suggestedNumber;

  @override
  ConsumerState<_AddDaySheet> createState() => _AddDaySheetState();
}

class _AddDaySheetState extends ConsumerState<_AddDaySheet> {
  late final _number = TextEditingController(
    text: widget.suggestedNumber.toString(),
  );
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _number.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final number = int.tryParse(_number.text.trim());
    if (number == null || number < 1 || _title.text.trim().isEmpty) {
      AppSnackBar.error(context, 'Vui lòng nhập số ngày và tên buổi.');
      return;
    }

    setState(() => _submitting = true);
    final result = await ref
        .read(trainingPlanApiProvider)
        .addDay(
          widget.weekId,
          dayNumber: number,
          title: _title.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() => _submitting = false);
        AppSnackBar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Thêm ngày tập',
      children: [
        AppTextField(
          label: 'Ngày số',
          controller: _number,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Tên buổi',
          controller: _title,
          hint: 'VD: Ngày squat',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Ghi chú (tùy chọn)',
          controller: _notes,
          hint: 'VD: Khởi động 10 phút',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: 'Thêm', onPressed: _submit, loading: _submitting),
      ],
    );
  }
}

class _ExerciseSheet extends ConsumerStatefulWidget {
  const _ExerciseSheet({
    required this.dayId,
    required this.existing,
    required this.suggestedOrder,
  });

  final String? dayId;
  final PlanExercise? existing;
  final int suggestedOrder;

  bool get isEdit => existing != null;

  @override
  ConsumerState<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends ConsumerState<_ExerciseSheet> {
  late final _name = TextEditingController(text: widget.existing?.exerciseName);
  late final _order = TextEditingController(
    text: widget.suggestedOrder.toString(),
  );
  late final _sets = TextEditingController(
    text: widget.existing?.sets?.toString() ?? '',
  );
  late final _reps = TextEditingController(text: widget.existing?.reps ?? '');
  late final _intensity = TextEditingController(
    text: widget.existing?.intensity ?? '',
  );
  late final _rest = TextEditingController(
    text: widget.existing?.restSeconds?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _order, _sets, _reps, _intensity, _rest, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _textOf(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  int? _intOf(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      AppSnackBar.error(context, 'Vui lòng nhập tên bài tập.');
      return;
    }
    final order = _intOf(_order) ?? widget.suggestedOrder;

    setState(() => _submitting = true);
    final api = ref.read(trainingPlanApiProvider);
    final result = widget.isEdit
        ? await api.updateExercise(
            widget.existing!.id,
            exerciseName: _name.text.trim(),
            orderIndex: order,
            sets: _intOf(_sets),
            reps: _textOf(_reps),
            intensity: _textOf(_intensity),
            restSeconds: _intOf(_rest),
            notes: _textOf(_notes),
          )
        : await api.addExercise(
            widget.dayId!,
            exerciseName: _name.text.trim(),
            orderIndex: order,
            sets: _intOf(_sets),
            reps: _textOf(_reps),
            intensity: _textOf(_intensity),
            restSeconds: _intOf(_rest),
            notes: _textOf(_notes),
          );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() => _submitting = false);
        AppSnackBar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: widget.isEdit ? 'Chỉnh sửa bài tập' : 'Thêm bài tập',
      children: [
        AppTextField(
          label: 'Tên bài tập',
          controller: _name,
          hint: 'VD: Barbell Back Squat',
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Thứ tự',
                controller: _order,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppTextField(
                label: 'Số hiệp',
                controller: _sets,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppTextField(
                label: 'Số lần',
                controller: _reps,
                hint: 'VD: 8-10',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Cường độ',
                controller: _intensity,
                hint: 'VD: RPE 7',
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppTextField(
                label: 'Nghỉ (giây)',
                controller: _rest,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Ghi chú (tùy chọn)',
          controller: _notes,
          hint: 'VD: Giữ chặt core',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: widget.isEdit ? 'Lưu' : 'Thêm',
          onPressed: _submit,
          loading: _submitting,
        ),
      ],
    );
  }
}
