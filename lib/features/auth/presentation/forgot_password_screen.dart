import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

/// Two-step password recovery: request a reset email, then paste the token
/// from that email together with the new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _emailSent = false;
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    setState(() => _error = null);
    if (!_emailKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_emailController.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case ApiSuccess():
        setState(() => _emailSent = true);
      case ApiFailure(:final error):
        setState(() => _error = error.userMessage);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _error = null);
    if (!_resetKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          token: _tokenController.text,
          newPassword: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case ApiSuccess():
        AppSnackBar.success(
          context,
          'Đặt lại mật khẩu thành công. Mời bạn đăng nhập.',
        );
        context.go(RouteNames.login);
      case ApiFailure(:final error):
        setState(() => _error = error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Quên mật khẩu',
      subtitle: _emailSent
          ? 'Dán mã trong email đặt lại mật khẩu và chọn mật khẩu mới.'
          : 'Nhập email đã đăng ký — chúng tôi sẽ gửi hướng dẫn đặt lại '
                'mật khẩu.',
      showBack: true,
      child: _emailSent ? _buildResetStep() : _buildEmailStep(),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Email',
            controller: _emailController,
            hint: 'ban@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            validator: Validators.email,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _sendEmail(),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) AuthErrorBanner(message: _error!),
          AppButton(
            label: 'Gửi email đặt lại mật khẩu',
            onPressed: _sendEmail,
            loading: _submitting,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Đã gửi email tới ${_emailController.text.trim()}. '
                    'Mở email và dán mã đặt lại vào ô dưới đây.',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Mã đặt lại mật khẩu',
            controller: _tokenController,
            hint: 'Dán mã trong email',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng dán mã từ email.'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Mật khẩu mới',
            controller: _passwordController,
            hint: 'Tối thiểu 8 ký tự',
            obscureText: _obscure,
            prefixIcon: Icons.lock_outline_rounded,
            validator: Validators.password,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            suffix: IconButton(
              tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null) AuthErrorBanner(message: _error!),
          AppButton(
            label: 'Đặt lại mật khẩu',
            onPressed: _resetPassword,
            loading: _submitting,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Gửi lại email',
            variant: AppButtonVariant.ghost,
            onPressed: _submitting ? null : _sendEmail,
          ),
        ],
      ),
    );
  }
}
