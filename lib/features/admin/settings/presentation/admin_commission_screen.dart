import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_info_row.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../data/models/platform_commission.dart';
import 'admin_commission_controller.dart';

/// Full-screen commission setting (reachable from "Thêm" and the dashboard).
class AdminCommissionScreen extends StatelessWidget {
  const AdminCommissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tỷ lệ hoa hồng')),
      body: const SafeArea(child: AdminCommissionView()),
    );
  }
}

/// The commission form itself — also embedded in the Finance tab.
class AdminCommissionView extends ConsumerWidget {
  const AdminCommissionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminCommissionControllerProvider);
    final controller = ref.read(adminCommissionControllerProvider.notifier);

    return switch (state) {
      AsyncData(:final value) => _CommissionForm(
        // Rebuilds the form when the backend value changes.
        key: ValueKey(value.commissionPercent),
        commission: value,
        onRefresh: controller.refresh,
      ),
      AsyncError(:final error) => AppErrorState(
        error: error is ApiError ? error : null,
        onRetry: controller.refresh,
      ),
      _ => const AppLoading(),
    };
  }
}

class _CommissionForm extends ConsumerStatefulWidget {
  const _CommissionForm({
    super.key,
    required this.commission,
    required this.onRefresh,
  });

  final PlatformCommission commission;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_CommissionForm> createState() => _CommissionFormState();
}

class _CommissionFormState extends ConsumerState<_CommissionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _percentController;
  late String _initialText;

  @override
  void initState() {
    super.initState();
    _initialText = _format(widget.commission.commissionPercent);
    _percentController = TextEditingController(text: _initialText);
    // Drives the unsaved-change detection that enables the save button.
    _percentController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  static String _format(num value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  bool get _isDirty => _percentController.text.trim() != _initialText;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final percent = CommissionRules.parse(_percentController.text);
    if (percent == null) return;

    final confirmed = await showAdminConfirmation(
      context,
      title: 'Cập nhật hoa hồng',
      message:
          'Đặt tỷ lệ hoa hồng nền tảng thành $percent%. Tỷ lệ mới chỉ áp dụng '
          'cho các đơn đăng ký phát sinh sau khi lưu; các đơn đã thanh toán giữ '
          'nguyên tỷ lệ đã ghi nhận.',
      confirmLabel: 'Cập nhật',
    );
    if (!confirmed || !mounted) return;

    final error = await ref
        .read(adminCommissionControllerProvider.notifier)
        .save(percent);
    if (!mounted) return;

    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    setState(() => _initialText = _percentController.text.trim());
    AppSnackBar.success(context, 'Đã cập nhật tỷ lệ hoa hồng.');
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(
      adminMutationBusyProvider(adminCommissionMutationKey),
    );

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Form(
        key: _formKey,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.xl,
          ),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text('Tỷ lệ hiện tại', style: AppTextStyles.bodySecondary),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    widget.commission.percentLabel,
                    style: AppTextStyles.displayTitle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const AdminSectionHeader(title: 'Cập nhật tỷ lệ'),
            AppTextField(
              label: 'Hoa hồng nền tảng (%)',
              controller: _percentController,
              hint: 'Ví dụ: 15',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: CommissionRules.validate,
              enabled: !busy,
              suffix: const Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(Icons.percent_rounded, size: 18),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Giá trị từ ${CommissionRules.min} đến ${CommissionRules.max}, '
              'tối đa 2 chữ số thập phân.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Tỷ lệ mới chỉ áp dụng cho các đơn đăng ký được tạo sau '
                      'khi lưu. Hoa hồng của các đơn đã thanh toán được ghi nhận '
                      'tại thời điểm mua và không bị tính lại.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            AppButton(
              label: 'Lưu thay đổi',
              icon: Icons.save_rounded,
              loading: busy,
              // Disabled until something actually changed — and while saving,
              // which also blocks a double submit.
              onPressed: (!_isDirty || busy) ? null : _submit,
            ),

            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                children: [
                  AdminInfoRow(
                    label: 'Cập nhật lần cuối',
                    value: DateFormatter.dateTime(widget.commission.updatedAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
