import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../training_packages/data/sport_options_provider.dart';
import '../data/coach_repository.dart';

/// Coach onboarding (`POST /api/coaches/register`). On success the token
/// pair is rotated so the new `coach` role lands in the JWT immediately.
class CoachOnboardingScreen extends ConsumerStatefulWidget {
  const CoachOnboardingScreen({super.key});

  @override
  ConsumerState<CoachOnboardingScreen> createState() =>
      _CoachOnboardingScreenState();
}

class _CoachOnboardingScreenState extends ConsumerState<CoachOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _manualSportController = TextEditingController();

  final Set<int> _selectedSportIds = {};
  final List<SportOption> _manualSports = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _headlineController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _manualSportController.dispose();
    super.dispose();
  }

  void _addManualSport() {
    final id = int.tryParse(_manualSportController.text.trim());
    if (id == null || id <= 0) return;
    setState(() {
      if (!_manualSports.any((s) => s.id == id)) {
        _manualSports.add((id: id, name: 'Môn #$id'));
      }
      _selectedSportIds.add(id);
      _manualSportController.clear();
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSportIds.isEmpty) {
      setState(() => _error = 'Vui lòng chọn ít nhất một môn thể thao.');
      return;
    }

    setState(() => _submitting = true);
    final experience = int.tryParse(_experienceController.text.trim());
    final result = await ref
        .read(coachRepositoryProvider)
        .register(
          headline: _headlineController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          experienceYears: experience,
          sportIds: _selectedSportIds.toList(),
        );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        // Rotate tokens so coach-only endpoints authorize right away.
        await ref.read(authControllerProvider.notifier).onRolesChanged();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chúc mừng! Bạn đã trở thành huấn luyện viên.'),
          ),
        );
        context.pop();
      case ApiFailure(:final error):
        setState(() {
          _submitting = false;
          _error = error.userMessage;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sportOptions = ref.watch(sportOptionsProvider);
    final knownSports = [
      ...?sportOptions.value,
      ..._manualSports.where(
        (m) => !(sportOptions.value ?? []).any((s) => s.id == m.id),
      ),
    ];

    return AuthScaffold(
      title: 'Trở thành huấn luyện viên',
      subtitle: 'Hoàn thiện hồ sơ để bắt đầu tạo gói tập và nhận học viên.',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Tiêu đề giới thiệu',
              controller: _headlineController,
              hint: 'VD: HLV thể hình 5 năm kinh nghiệm',
              validator: Validators.headline,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Giới thiệu bản thân (tùy chọn)',
              controller: _bioController,
              hint: 'Kinh nghiệm, chứng chỉ, phong cách huấn luyện…',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Số năm kinh nghiệm (tùy chọn)',
              controller: _experienceController,
              hint: '0 – 60',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  Validators.optionalRange(v, 0, 60, 'Số năm kinh nghiệm'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Môn thể thao giảng dạy',
              style: AppTextStyles.bodySecondary.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (sportOptions.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (knownSports.isEmpty)
              Text(
                'Chưa lấy được danh mục môn thể thao — nhập mã môn bên dưới.',
                style: AppTextStyles.caption,
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final sport in knownSports)
                    FilterChip(
                      label: Text(sport.name),
                      selected: _selectedSportIds.contains(sport.id),
                      onSelected: (selected) => setState(() {
                        selected
                            ? _selectedSportIds.add(sport.id)
                            : _selectedSportIds.remove(sport.id);
                      }),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Thêm mã môn thể thao',
                    controller: _manualSportController,
                    hint: 'VD: 1',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton(
                  label: 'Thêm',
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.large,
                  expanded: false,
                  onPressed: _addManualSport,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                'Danh mục môn được tổng hợp từ các gói tập đang mở bán. Nếu '
                'môn của bạn chưa có, hãy nhập mã môn do quản trị viên cung cấp.',
                style: AppTextStyles.caption.copyWith(color: AppColors.info),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) AuthErrorBanner(message: _error!),
            AppButton(
              label: 'Đăng ký làm huấn luyện viên',
              onPressed: _submit,
              loading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}
