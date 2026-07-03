import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case ApiSuccess():
        context.go(RouteNames.verifyEmail, extra: _emailController.text.trim());
      case ApiFailure(:final error):
        setState(() => _error = error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Tạo tài khoản',
      subtitle: 'Đăng ký để đặt lịch tập cùng huấn luyện viên phù hợp.',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Họ và tên',
              controller: _nameController,
              hint: 'Nguyễn Văn A',
              prefixIcon: Icons.person_outline_rounded,
              validator: Validators.fullName,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              hint: 'ban@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              validator: Validators.email,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Mật khẩu',
              controller: _passwordController,
              hint: 'Tối thiểu 8 ký tự',
              obscureText: _obscure,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.password,
              textInputAction: TextInputAction.next,
              suffix: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Nhập lại mật khẩu',
              controller: _confirmController,
              hint: '••••••••',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
              validator: (v) =>
                  Validators.confirmPassword(v, _passwordController.text),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) AuthErrorBanner(message: _error!),
            AppButton(
              label: 'Đăng ký',
              onPressed: _submit,
              loading: _submitting,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Đã có tài khoản?', style: AppTextStyles.bodySecondary),
                TextButton(
                  onPressed: () => context.go(RouteNames.login),
                  child: const Text('Đăng nhập'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
