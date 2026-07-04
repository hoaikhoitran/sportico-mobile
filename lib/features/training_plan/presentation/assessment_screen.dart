import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/models/learner_assessment.dart';
import '../data/training_plan_api.dart';
import 'training_plan_providers.dart';

/// Learner's intake assessment for one booking. Learners create/update it;
/// coaches read it to author the plan.
class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({
    super.key,
    required this.bookingId,
    required this.asCoach,
  });

  final String bookingId;
  final bool asCoach;

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final assessment = ref.watch(assessmentProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá đầu vào')),
      body: SafeArea(
        child: switch (assessment) {
          AsyncData(:final value) => _buildBody(value),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () => ref.invalidate(assessmentProvider(widget.bookingId)),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }

  Widget _buildBody(LearnerAssessment? assessment) {
    if (assessment == null && widget.asCoach) {
      return const AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Chưa có đánh giá đầu vào',
        message: 'Học viên chưa điền hồ sơ đánh giá cho gói tập này.',
      );
    }
    if (assessment == null || _editing) {
      return _AssessmentForm(
        bookingId: widget.bookingId,
        existing: assessment,
        onDone: () {
          setState(() => _editing = false);
          ref.invalidate(assessmentProvider(widget.bookingId));
        },
      );
    }
    return _AssessmentView(
      assessment: assessment,
      canEdit: !widget.asCoach,
      onEdit: () => setState(() => _editing = true),
    );
  }
}

class _AssessmentView extends StatelessWidget {
  const _AssessmentView({
    required this.assessment,
    required this.canEdit,
    required this.onEdit,
  });

  final LearnerAssessment assessment;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
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
              Text('Mục tiêu', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              _Row('Mục tiêu chính', PlanLabels.goal(assessment.goalType)),
              if (assessment.goalDescription != null)
                _Row('Mô tả', assessment.goalDescription!),
              _Row(
                'Trình độ hiện tại',
                PlanLabels.level(assessment.currentLevel),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chỉ số cơ thể', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              _Row(
                'Chiều cao',
                assessment.heightCm != null ? '${assessment.heightCm} cm' : '—',
              ),
              _Row(
                'Cân nặng',
                assessment.weightKg != null ? '${assessment.weightKg} kg' : '—',
              ),
              _Row(
                'Tỷ lệ mỡ',
                assessment.bodyFatPercent != null
                    ? '${assessment.bodyFatPercent}%'
                    : '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sức khỏe & lịch sử', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              _Row('Ghi chú sức khỏe', assessment.healthNotes ?? '—'),
              _Row('Chấn thương', assessment.injuryNotes ?? '—'),
              _Row('Lịch sử luyện tập', assessment.trainingHistory ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Điều kiện luyện tập', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              _Row('Số ngày rảnh/tuần', assessment.availableDaysPerWeek ?? '—'),
              _Row(
                'Thời lượng mỗi buổi',
                assessment.preferredSessionDurationMinutes != null
                    ? '${assessment.preferredSessionDurationMinutes} phút'
                    : '—',
              ),
              _Row('Dụng cụ sẵn có', assessment.equipmentAvailable ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Cập nhật lần cuối: ${DateFormatter.dateTime(assessment.updatedAt)}',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        if (canEdit) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Chỉnh sửa đánh giá',
            variant: AppButtonVariant.secondary,
            onPressed: onEdit,
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTextStyles.bodySecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentForm extends ConsumerStatefulWidget {
  const _AssessmentForm({
    required this.bookingId,
    required this.existing,
    required this.onDone,
  });

  final String bookingId;
  final LearnerAssessment? existing;
  final VoidCallback onDone;

  @override
  ConsumerState<_AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends ConsumerState<_AssessmentForm> {
  final _formKey = GlobalKey<FormState>();
  late String? _goalType = widget.existing?.goalType;
  late String? _currentLevel = widget.existing?.currentLevel;
  late final _goalDescription = TextEditingController(
    text: widget.existing?.goalDescription,
  );
  late final _height = TextEditingController(
    text: widget.existing?.heightCm?.toString() ?? '',
  );
  late final _weight = TextEditingController(
    text: widget.existing?.weightKg?.toString() ?? '',
  );
  late final _bodyFat = TextEditingController(
    text: widget.existing?.bodyFatPercent?.toString() ?? '',
  );
  late final _healthNotes = TextEditingController(
    text: widget.existing?.healthNotes,
  );
  late final _injuryNotes = TextEditingController(
    text: widget.existing?.injuryNotes,
  );
  late final _history = TextEditingController(
    text: widget.existing?.trainingHistory,
  );
  late final _daysPerWeek = TextEditingController(
    text: widget.existing?.availableDaysPerWeek,
  );
  late final _duration = TextEditingController(
    text: widget.existing?.preferredSessionDurationMinutes?.toString() ?? '',
  );
  late final _equipment = TextEditingController(
    text: widget.existing?.equipmentAvailable,
  );

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _goalDescription,
      _height,
      _weight,
      _bodyFat,
      _healthNotes,
      _injuryNotes,
      _history,
      _daysPerWeek,
      _duration,
      _equipment,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  num? _numOf(TextEditingController c) =>
      c.text.trim().isEmpty ? null : num.tryParse(c.text.trim());

  String? _textOf(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_goalType == null) {
      setState(() => _error = 'Vui lòng chọn mục tiêu luyện tập.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final draft = AssessmentDraft(
      goalType: _goalType!,
      goalDescription: _textOf(_goalDescription),
      heightCm: _numOf(_height),
      weightKg: _numOf(_weight),
      bodyFatPercent: _numOf(_bodyFat),
      currentLevel: _currentLevel,
      healthNotes: _textOf(_healthNotes),
      injuryNotes: _textOf(_injuryNotes),
      trainingHistory: _textOf(_history),
      availableDaysPerWeek: _textOf(_daysPerWeek),
      preferredSessionDurationMinutes: _numOf(_duration)?.toInt(),
      equipmentAvailable: _textOf(_equipment),
    );

    setState(() => _submitting = true);
    final api = ref.read(trainingPlanApiProvider);
    final result = widget.existing == null
        ? await api.createAssessment(widget.bookingId, draft)
        : await api.updateAssessment(widget.bookingId, draft);
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        AppSnackBar.success(context, 'Đã lưu đánh giá đầu vào.');
        widget.onDone();
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
            'Chia sẻ thể trạng và mục tiêu để huấn luyện viên thiết kế giáo án '
            'phù hợp với bạn.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionLabel('Mục tiêu'),
          _GoalChips(
            options: PlanLabels.goalOptions,
            selected: _goalType,
            onSelected: (v) => setState(() => _goalType = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Mô tả mục tiêu (tùy chọn)',
            controller: _goalDescription,
            hint: 'VD: Tăng 5kg cơ trong 3 tháng',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SectionLabel('Trình độ hiện tại'),
          _GoalChips(
            options: PlanLabels.levelOptions,
            selected: _currentLevel,
            onSelected: (v) => setState(() => _currentLevel = v),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionLabel('Chỉ số cơ thể (tùy chọn)'),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Cao (cm)',
                  controller: _height,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppTextField(
                  label: 'Nặng (kg)',
                  controller: _weight,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppTextField(
                  label: 'Mỡ (%)',
                  controller: _bodyFat,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Ghi chú sức khỏe (tùy chọn)',
            controller: _healthNotes,
            hint: 'Bệnh nền, thuốc đang dùng…',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Chấn thương (tùy chọn)',
            controller: _injuryNotes,
            hint: 'VD: Đau khớp gối nhẹ',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Lịch sử luyện tập (tùy chọn)',
            controller: _history,
            hint: 'VD: 1 năm tập gym không đều',
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Ngày rảnh/tuần',
                  controller: _daysPerWeek,
                  hint: 'VD: 3',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppTextField(
                  label: 'Phút mỗi buổi',
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Dụng cụ sẵn có (tùy chọn)',
            controller: _equipment,
            hint: 'VD: Tạ đơn, ghế tập',
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
            label: widget.existing == null ? 'Gửi đánh giá' : 'Lưu thay đổi',
            onPressed: _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.bodySecondary.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GoalChips extends StatelessWidget {
  const _GoalChips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      children: [
        for (final (key, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: selected == key,
            onSelected: (_) => onSelected(key),
          ),
      ],
    );
  }
}
