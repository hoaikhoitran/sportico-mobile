import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_result.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Post-registration info screen. Verification normally happens by opening
/// the link in the email; pasting the token manually also works for cases
/// where the link cannot be opened on this device.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _tokenController = TextEditingController();
  bool _showTokenField = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Vui lòng dán mã xác thực từ email.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(token);
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case ApiSuccess():
        AppSnackBar.success(
          context,
          'Xác thực email thành công. Mời bạn đăng nhập.',
        );
        context.go(RouteNames.login);
      case ApiFailure(:final error):
        setState(() => _error = error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Kiểm tra email của bạn',
      subtitle: widget.email != null
          ? 'Chúng tôi đã gửi liên kết xác thực tới ${widget.email}.'
          : 'Chúng tôi đã gửi liên kết xác thực tới email của bạn.',
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mở email và nhấn vào liên kết xác thực để kích hoạt tài '
                    'khoản. Sau đó quay lại đây để đăng nhập.',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Tôi đã xác thực — Đăng nhập',
            onPressed: () => context.go(RouteNames.login),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: _showTokenField
                ? 'Ẩn nhập mã thủ công'
                : 'Nhập mã xác thực thủ công',
            variant: AppButtonVariant.ghost,
            onPressed: () => setState(() => _showTokenField = !_showTokenField),
          ),
          if (_showTokenField) ...[
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Mã xác thực',
              controller: _tokenController,
              hint: 'Dán mã token trong liên kết xác thực',
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null) AuthErrorBanner(message: _error!),
            AppButton(
              label: 'Xác thực',
              variant: AppButtonVariant.secondary,
              onPressed: _verify,
              loading: _submitting,
            ),
          ],
        ],
      ),
    );
  }
}
