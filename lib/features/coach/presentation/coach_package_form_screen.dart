import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../training_packages/data/models/training_package.dart';
import '../../training_packages/data/models/training_package_draft.dart';
import '../../training_packages/data/sport_options_provider.dart';
import '../../training_packages/data/training_package_repository.dart';
import 'coach_packages_controller.dart';

/// Create / edit a training package with its full fixed schedule.
/// Mirrors backend rules client-side: sessions cover 1..N, within the
/// package date range, start < end, no overlaps, offline needs a location.
class CoachPackageFormScreen extends ConsumerStatefulWidget {
  const CoachPackageFormScreen({super.key, this.packageId});

  /// Null → create; set → edit (allowed while not published).
  final String? packageId;

  bool get isEdit => packageId != null;

  @override
  ConsumerState<CoachPackageFormScreen> createState() =>
      _CoachPackageFormScreenState();
}

class _SlotFormData {
  DateTime? date;
  TimeOfDay? start;
  TimeOfDay? end;
  final TextEditingController maxParticipants = TextEditingController(
    text: '1',
  );
  final TextEditingController note = TextEditingController();

  void dispose() {
    maxParticipants.dispose();
    note.dispose();
  }

  DateTime? get startDateTime => (date == null || start == null)
      ? null
      : DateTime(
          date!.year,
          date!.month,
          date!.day,
          start!.hour,
          start!.minute,
        );

  DateTime? get endDateTime => (date == null || end == null)
      ? null
      : DateTime(date!.year, date!.month, date!.day, end!.hour, end!.minute);
}

class _CoachPackageFormScreenState
    extends ConsumerState<CoachPackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _manualSportController = TextEditingController();

  int? _sportId;
  final List<SportOption> _manualSports = [];
  bool _isOnline = false;
  String? _level;
  String? _goalType;
  DateTime? _startDate;
  DateTime? _endDate;
  final List<_SlotFormData> _slots = [_SlotFormData()];

  bool _submitting = false;
  bool _prefilled = false;
  String? _error;

  static const _levels = [
    ('beginner', 'Người mới'),
    ('intermediate', 'Trung cấp'),
    ('advanced', 'Nâng cao'),
  ];

  static const _goals = [
    ('muscle_gain', 'Tăng cơ'),
    ('weight_loss', 'Giảm cân'),
    ('endurance', 'Sức bền'),
    ('general_fitness', 'Thể lực chung'),
    ('skill_improvement', 'Nâng cao kỹ năng'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _manualSportController.dispose();
    for (final slot in _slots) {
      slot.dispose();
    }
    super.dispose();
  }

  void _prefillFrom(TrainingPackage package) {
    if (_prefilled) return;
    _prefilled = true;
    _titleController.text = package.title;
    _descriptionController.text = package.description ?? '';
    _priceController.text = package.price.toStringAsFixed(0);
    _locationController.text = package.location ?? '';
    _sportId = package.sportId;
    if (package.sportId > 0) {
      _manualSports.add((id: package.sportId, name: package.sportName));
    }
    _isOnline = package.isOnline;
    _level = package.level;
    _goalType = package.goalType;
    _startDate = package.startDate;
    _endDate = package.endDate;
    for (final slot in _slots) {
      slot.dispose();
    }
    _slots
      ..clear()
      ..addAll(
        package.sessions.map((s) {
          final data = _SlotFormData();
          final start = s.startTime;
          final end = s.endTime;
          if (start != null) {
            data.date = DateTime(start.year, start.month, start.day);
            data.start = TimeOfDay.fromDateTime(start);
          }
          if (end != null) data.end = TimeOfDay.fromDateTime(end);
          data.maxParticipants.text = s.maxParticipants.toString();
          data.note.text = s.note ?? '';
          return data;
        }),
      );
    if (_slots.isEmpty) _slots.add(_SlotFormData());
  }

  String? _validateSchedule() {
    if (_sportId == null) return 'Vui lòng chọn môn thể thao.';
    if (_startDate == null || _endDate == null) {
      return 'Vui lòng chọn thời gian bắt đầu và kết thúc của gói.';
    }
    if (_endDate!.isBefore(_startDate!)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu.';
    }
    if (!_isOnline && _locationController.text.trim().isEmpty) {
      return 'Gói tập trực tiếp cần có địa điểm.';
    }

    final ranges = <(DateTime, DateTime, int)>[];
    for (final (i, slot) in _slots.indexed) {
      final start = slot.startDateTime;
      final end = slot.endDateTime;
      if (start == null || end == null) {
        return 'Buổi ${i + 1}: chưa chọn đủ ngày và giờ.';
      }
      if (!end.isAfter(start)) {
        return 'Buổi ${i + 1}: giờ kết thúc phải sau giờ bắt đầu.';
      }
      if (start.isBefore(_startDate!) ||
          end.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return 'Buổi ${i + 1}: nằm ngoài thời gian của gói.';
      }
      final max = int.tryParse(slot.maxParticipants.text.trim());
      if (max == null || max < 1) {
        return 'Buổi ${i + 1}: số học viên tối đa phải từ 1 trở lên.';
      }
      ranges.add((start, end, i + 1));
    }
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    for (var i = 1; i < ranges.length; i++) {
      if (ranges[i].$1.isBefore(ranges[i - 1].$2)) {
        return 'Buổi ${ranges[i - 1].$3} và buổi ${ranges[i].$3} bị trùng giờ.';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final scheduleError = _validateSchedule();
    if (scheduleError != null) {
      setState(() => _error = scheduleError);
      return;
    }

    final location = _locationController.text.trim().isEmpty && !_isOnline
        ? null
        : _locationController.text.trim();
    // The pickers yield local calendar dates; send them as UTC day bounds.
    // A plain `.toUtc()` of local midnight would land on the previous UTC
    // day (UTC+7), pushing last-day slots outside [startDate, endDate] on
    // the backend.
    final start = _startDate!;
    final end = _endDate!;
    final draft = TrainingPackageDraft(
      sportId: _sportId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      price: num.parse(_priceController.text.trim()),
      startDate: DateTime.utc(start.year, start.month, start.day),
      endDate: DateTime.utc(end.year, end.month, end.day, 23, 59, 59),
      location: _isOnline ? null : location,
      isOnline: _isOnline,
      level: _level,
      goalType: _goalType,
      sessions: [
        for (final (i, slot) in _slots.indexed)
          SessionSlotDraft(
            sessionNumber: i + 1,
            startTime: slot.startDateTime!,
            endTime: slot.endDateTime!,
            level: _level,
            maxParticipants: int.parse(slot.maxParticipants.text.trim()),
            location: _isOnline ? null : location,
            isOnline: _isOnline,
            note: slot.note.text.trim().isEmpty ? null : slot.note.text.trim(),
          ),
      ],
    );

    setState(() => _submitting = true);
    final repository = ref.read(trainingPackageRepositoryProvider);
    final result = widget.isEdit
        ? await repository.update(widget.packageId!, draft)
        : await repository.create(draft);
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        ref.invalidate(coachPackagesControllerProvider);
        AppSnackBar.success(
          context,
          widget.isEdit
              ? 'Đã cập nhật gói tập.'
              : 'Đã tạo gói tập — chờ quản trị viên duyệt.',
        );
        context.pop();
      case ApiFailure(:final error):
        setState(() {
          _submitting = false;
          _error = error.userMessage;
        });
    }
  }

  Future<void> _pickPackageDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final detail = ref.watch(coachPackageDetailProvider(widget.packageId!));
      switch (detail) {
        case AsyncData(:final value):
          _prefillFrom(value);
        case AsyncError(:final error):
          return Scaffold(
            appBar: AppBar(title: const Text('Chỉnh sửa gói tập')),
            body: AppErrorState(
              message: error.toString(),
              onRetry: () =>
                  ref.invalidate(coachPackageDetailProvider(widget.packageId!)),
            ),
          );
        default:
          return Scaffold(
            appBar: AppBar(title: const Text('Chỉnh sửa gói tập')),
            body: const AppLoading(),
          );
      }
    }

    final sportOptions = ref.watch(sportOptionsProvider);
    final knownSports = [
      ...?sportOptions.value,
      ..._manualSports.where(
        (m) => !(sportOptions.value ?? []).any((s) => s.id == m.id),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Chỉnh sửa gói tập' : 'Tạo gói tập'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              AppSpacing.xl,
            ),
            children: [
              AppTextField(
                label: 'Tên gói tập',
                controller: _titleController,
                hint: 'VD: Giảm cân 8 tuần cùng HLV',
                validator: (v) => Validators.required(v, 'tên gói tập'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Môn thể thao',
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (sportOptions.hasError && knownSports.isEmpty)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Không tải được danh mục môn thể thao.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(sportOptionsProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                )
              else if (knownSports.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    for (final sport in knownSports)
                      ChoiceChip(
                        label: Text(sport.name),
                        selected: _sportId == sport.id,
                        onSelected: (_) => setState(() => _sportId = sport.id),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Hoặc nhập mã môn',
                      controller: _manualSportController,
                      hint: 'VD: 1',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppButton(
                    label: 'Chọn',
                    variant: AppButtonVariant.secondary,
                    expanded: false,
                    onPressed: () {
                      final id = int.tryParse(
                        _manualSportController.text.trim(),
                      );
                      if (id == null || id <= 0) return;
                      setState(() {
                        if (!_manualSports.any((s) => s.id == id)) {
                          _manualSports.add((id: id, name: 'Môn #$id'));
                        }
                        _sportId = id;
                        _manualSportController.clear();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Mô tả (tùy chọn)',
                controller: _descriptionController,
                hint: 'Nội dung, giáo trình, đối tượng phù hợp…',
                maxLines: 4,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Giá gói (VNĐ)',
                controller: _priceController,
                hint: 'VD: 1000000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => Validators.positiveNumber(v, 'Giá gói'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _Dropdown(
                      label: 'Trình độ',
                      value: _level,
                      options: _levels,
                      onChanged: (v) => setState(() => _level = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _Dropdown(
                      label: 'Mục tiêu',
                      value: _goalType,
                      options: _goals,
                      onChanged: (v) => setState(() => _goalType = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                value: _isOnline,
                onChanged: (v) => setState(() => _isOnline = v),
                title: Text('Tập online', style: AppTextStyles.body),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.primary,
              ),
              if (!_isOnline)
                AppTextField(
                  label: 'Địa điểm',
                  controller: _locationController,
                  hint: 'VD: Phòng gym ABC, Quận 1',
                  validator: (v) =>
                      _isOnline ? null : Validators.required(v, 'địa điểm'),
                ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Ngày bắt đầu',
                      value: _startDate,
                      onTap: () => _pickPackageDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _DateField(
                      label: 'Ngày kết thúc',
                      value: _endDate,
                      onTap: () => _pickPackageDate(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lịch tập cố định',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  Text(
                    '${_slots.length} buổi',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Người tập đăng ký sẽ theo đúng lịch này. Lịch không được '
                'trùng giờ giữa các buổi.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (index, slot) in _slots.indexed) ...[
                _SlotEditor(
                  index: index,
                  slot: slot,
                  canRemove: _slots.length > 1,
                  onRemove: () => setState(() {
                    _slots.removeAt(index).dispose();
                  }),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              AppButton(
                label: 'Thêm buổi tập',
                icon: Icons.add_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () => setState(() => _slots.add(_SlotFormData())),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_error != null) ...[
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
              ],
              AppButton(
                label: widget.isEdit ? 'Lưu thay đổi' : 'Tạo gói tập',
                onPressed: _submit,
                loading: _submitting,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.isEdit
                    ? 'Lịch tập mới sẽ thay thế toàn bộ lịch cũ.'
                    : 'Gói tập sẽ ở trạng thái "Chờ duyệt" cho tới khi quản '
                          'trị viên phê duyệt.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<(String, String)> options;
  final ValueChanged<String?> onChanged;

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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: AppTextStyles.body,
          hint: Text('Chọn', style: AppTextStyles.bodySecondary),
          items: [
            for (final (key, label) in options)
              DropdownMenuItem(value: key, child: Text(label)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
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
              suffixIcon: Icon(Icons.calendar_today_rounded, size: 17),
            ),
            child: Text(
              value == null ? 'Chọn ngày' : DateFormatter.date(value),
              style: value == null
                  ? AppTextStyles.bodySecondary
                  : AppTextStyles.body,
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotEditor extends StatelessWidget {
  const _SlotEditor({
    required this.index,
    required this.slot,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _SlotFormData slot;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: slot.date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) return;
    slot.date = picked;
    onChanged();
  }

  Future<void> _pickTime(BuildContext context, {required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? slot.start : slot.end) ??
          const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null) return;
    isStart ? slot.start = picked : slot.end = picked;
    onChanged();
  }

  String _timeLabel(TimeOfDay? time) => time == null
      ? '--:--'
      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Buổi ${index + 1}',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _ChipButton(
                  icon: Icons.event_rounded,
                  label: slot.date == null
                      ? 'Chọn ngày'
                      : DateFormatter.date(slot.date),
                  onTap: () => _pickDate(context),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 3,
                child: _ChipButton(
                  icon: Icons.schedule_rounded,
                  label: _timeLabel(slot.start),
                  onTap: () => _pickTime(context, isStart: true),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 3,
                child: _ChipButton(
                  icon: Icons.schedule_rounded,
                  label: _timeLabel(slot.end),
                  onTap: () => _pickTime(context, isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Học viên tối đa',
                  controller: slot.maxParticipants,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: 'Ghi chú (tùy chọn)',
                  controller: slot.note,
                  hint: 'VD: Buổi khởi động',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          color: AppColors.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.accentBlue),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
