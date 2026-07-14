import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_section_header.dart';

/// "Thêm": platform settings, the admin's own account, and sign-out.
class AdminMoreScreen extends ConsumerWidget {
  const AdminMoreScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Đăng xuất',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục quản trị.',
      confirmLabel: 'Đăng xuất',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    // An account that also holds a learner/coach role keeps access to the
    // normal app — the admin area is an addition, not a replacement.
    final hasUserApp = auth.isLearner || auth.isCoach;

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.xl,
          ),
          children: [
            const AdminSectionHeader(title: 'Tài khoản'),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.accentBlueSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName
                              : 'Quản trị viên',
                          style: AppTextStyles.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user?.email.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            user!.email,
                            style: AppTextStyles.bodySecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xxs,
                          children: [
                            for (final role in auth.roles)
                              AppBadge(
                                label: AdminRoles.label(role),
                                tone: AdminRoles.tone(role),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const AdminSectionHeader(title: 'Cấu hình nền tảng'),
            _MoreTile(
              icon: Icons.percent_rounded,
              title: 'Tỷ lệ hoa hồng',
              subtitle: 'Xem và cập nhật hoa hồng nền tảng',
              onTap: () => context.push(RouteNames.adminCommission),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (hasUserApp) ...[
              const AdminSectionHeader(title: 'Chuyển khu vực'),
              _MoreTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Sang ứng dụng người dùng',
                subtitle: 'Truy cập trải nghiệm người tập / huấn luyện viên',
                onTap: () => context.go(RouteNames.home),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            _MoreTile(
              icon: Icons.logout_rounded,
              title: 'Đăng xuất',
              subtitle: 'Kết thúc phiên quản trị',
              danger: true,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;
    final tint = danger ? AppColors.dangerSoft : AppColors.accentBlueSoft;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: danger ? AppColors.danger : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
