import 'package:flutter/material.dart';
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
import '../../../core/widgets/app_text_field.dart';
import '../data/models/progress_checkin.dart';
import '../data/training_plan_api.dart';
import 'training_plan_providers.dart';

/// Progress check-ins for one booking: learner logs metrics, coach responds
/// with feedback.
class ProgressCheckInsScreen extends ConsumerWidget {
  const ProgressCheckInsScreen({
    super.key,
    required this.bookingId,
    required this.asCoach,
  });

  final String bookingId;
  final bool asCoach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkIns = ref.watch(progressCheckInsProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi nhận tiến độ')),
      floatingActionButton: asCoach
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await showModalBottomSheet<bool>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (context) => _CheckInSheet(bookingId: bookingId),
                );
                if (created == true) {
                  ref.invalidate(progressCheckInsProvider(bookingId));
                }
              },
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ghi nhận'),
            ),
      body: SafeArea(
        child: switch (checkIns) {
          AsyncData(:final value) =>
            value.isEmpty
                ? AppEmptyState(
                    icon: Icons.monitor_weight_outlined,
                    title: 'Chưa có ghi nhận nào',
                    message: asCoach
                        ? 'Học viên chưa ghi nhận tiến độ cho gói tập này.'
                        : 'Ghi lại cân nặng, cảm nhận sau mỗi giai đoạn để HLV '
                              'theo dõi tiến bộ của bạn.',
                  )
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(progressCheckInsProvider(bookingId)),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.xs,
                        AppSpacing.screenH,
                        96,
                      ),
                      itemCount: value.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _CheckInCard(
                        checkIn: value[index],
                        asCoach: asCoach,
                        onFeedbackGiven: () =>
                            ref.invalidate(progressCheckInsProvider(bookingId)),
                      ),
                    ),
                  ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () => ref.invalidate(progressCheckInsProvider(bookingId)),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _CheckInCard extends ConsumerWidget {
  const _CheckInCard({
    required this.checkIn,
    required this.asCoach,
    required this.onFeedbackGiven,
  });

  final ProgressCheckIn checkIn;
  final bool asCoach;
  final VoidCallback onFeedbackGiven;

  static const _energyLabels = {
    'good': 'Tốt',
    'ok': 'Bình thường',
    'poor': 'Kém',
  };

  Future<void> _giveFeedback(BuildContext context, WidgetRef ref) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FeedbackSheet(
        checkInId: checkIn.id,
        existing: checkIn.coachFeedback,
      ),
    );
    if (saved == true) onFeedbackGiven();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = <String>[
      if (checkIn.weightKg != null) '${checkIn.weightKg} kg',
      if (checkIn.bodyFatPercent != null) 'Mỡ ${checkIn.bodyFatPercent}%',
      if (checkIn.waistCm != null) 'Eo ${checkIn.waistCm} cm',
      if (checkIn.energyLevel != null)
        'Năng lượng: ${_energyLabels[checkIn.energyLevel] ?? checkIn.energyLevel}',
      if (checkIn.sleepQuality != null)
        'Ngủ: ${_energyLabels[checkIn.sleepQuality] ?? checkIn.sleepQuality}',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available_rounded,
                size: 17,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                DateFormatter.date(checkIn.checkInDate),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final metric in metrics)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusPill,
                      ),
                    ),
                    child: Text(metric, style: AppTextStyles.caption),
                  ),
              ],
            ),
          ],
          if (checkIn.learnerNote?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(checkIn.learnerNote!, style: AppTextStyles.body),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (checkIn.coachFeedback?.isNotEmpty == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accentBlueSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phản hồi của HLV',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(checkIn.coachFeedback!, style: AppTextStyles.body),
                ],
              ),
            )
          else if (asCoach)
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Phản hồi',
                icon: Icons.reply_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                expanded: false,
                onPressed: () => _giveFeedback(context, ref),
              ),
            )
          else
            Text('Chưa có phản hồi từ HLV.', style: AppTextStyles.caption),
          if (asCoach && checkIn.coachFeedback?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: 'Sửa phản hồi',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                expanded: false,
                onPressed: () => _giveFeedback(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Learner's new check-in form.
class _CheckInSheet extends ConsumerStatefulWidget {
  const _CheckInSheet({required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<_CheckInSheet> {
  DateTime _date = DateTime.now();
  final _weight = TextEditingController();
  final _bodyFat = TextEditingController();
  final _waist = TextEditingController();
  final _note = TextEditingController();
  String? _energy;
  String? _sleep;
  bool _submitting = false;

  static const _qualityOptions = [
    ('good', 'Tốt'),
    ('ok', 'Bình thường'),
    ('poor', 'Kém'),
  ];

  @override
  void dispose() {
    _weight.dispose();
    _bodyFat.dispose();
    _waist.dispose();
    _note.dispose();
    super.dispose();
  }

  num? _numOf(TextEditingController c) =>
      c.text.trim().isEmpty ? null : num.tryParse(c.text.trim());

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await ref
        .read(trainingPlanApiProvider)
        .createCheckIn(
          widget.bookingId,
          checkInDate: _date,
          weightKg: _numOf(_weight),
          bodyFatPercent: _numOf(_bodyFat),
          waistCm: _numOf(_waist),
          energyLevel: _energy,
          sleepQuality: _sleep,
          learnerNote: _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }

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
            Text('Ghi nhận tiến độ', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.calendar_today_rounded, size: 17),
                ),
                child: Text(
                  DateFormatter.date(_date),
                  style: AppTextStyles.body,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
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
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppTextField(
                    label: 'Eo (cm)',
                    controller: _waist,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _QualityPicker(
              label: 'Mức năng lượng',
              options: _qualityOptions,
              selected: _energy,
              onSelected: (v) => setState(() => _energy = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QualityPicker(
              label: 'Chất lượng giấc ngủ',
              options: _qualityOptions,
              selected: _sleep,
              onSelected: (v) => setState(() => _sleep = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Cảm nhận (tùy chọn)',
              controller: _note,
              hint: 'VD: Cảm thấy khỏe hơn tuần trước',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Lưu ghi nhận',
              onPressed: _submit,
              loading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityPicker extends StatelessWidget {
  const _QualityPicker({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelected;

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
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final (key, text) in options)
              ChoiceChip(
                label: Text(text),
                selected: selected == key,
                onSelected: (_) => onSelected(key),
              ),
          ],
        ),
      ],
    );
  }
}

/// Coach feedback form.
class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet({required this.checkInId, this.existing});

  final String checkInId;
  final String? existing;

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  late final _feedback = TextEditingController(text: widget.existing);
  bool _submitting = false;

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_feedback.text.trim().isEmpty) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(trainingPlanApiProvider)
        .giveCoachFeedback(widget.checkInId, _feedback.text.trim());
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
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
          Text('Phản hồi học viên', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nội dung phản hồi',
            controller: _feedback,
            hint: 'VD: Tiến bộ tốt, tuần sau tăng 2.5kg.',
            maxLines: 4,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Gửi phản hồi',
            onPressed: _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }
}
