import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/presentation/auth_controller.dart';

/// Shown to admin-only accounts — phase 1 has no admin features on mobile.
class AdminUnsupportedScreen extends ConsumerWidget {
  const AdminUnsupportedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.warningSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 36,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tài khoản quản trị',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Các tính năng quản trị chưa được hỗ trợ đầy đủ trên ứng dụng '
                'di động. Vui lòng sử dụng trang quản trị trên web.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Đăng xuất',
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
