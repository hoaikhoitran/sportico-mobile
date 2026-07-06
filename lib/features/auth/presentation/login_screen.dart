import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_controller.dart';
import 'widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final error = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text, _passwordController.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error?.userMessage;
    });
    // On success the router redirect takes over.
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Chào mừng trở lại',
      subtitle: 'Đăng nhập để tiếp tục hành trình luyện tập của bạn.',
      child: Form(
        key: _formKey,
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Mật khẩu',
              controller: _passwordController,
              hint: '••••••••',
              obscureText: _obscure,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.password,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(RouteNames.forgotPassword),
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_error != null) AuthErrorBanner(message: _error!),
            AppButton(
              label: 'Đăng nhập',
              onPressed: _submit,
              loading: _submitting,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Khám phá gói tập',
              icon: Icons.explore_outlined,
              variant: AppButtonVariant.ghost,
              onPressed: () => context.go(RouteNames.packages),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Chưa có tài khoản?', style: AppTextStyles.bodySecondary),
                TextButton(
                  onPressed: () => context.push(RouteNames.register),
                  child: const Text('Đăng ký ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
