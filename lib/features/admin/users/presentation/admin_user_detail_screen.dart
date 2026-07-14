import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../moderation/presentation/widgets/moderation_action_bar.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_info_row.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/admin_user.dart';
import 'admin_users_controller.dart';

/// One account: profile, roles, state, and the admin actions on it.
class AdminUserDetailScreen extends ConsumerWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  Future<void> _confirmDeactivate(
    BuildContext context,
    WidgetRef ref,
    AdminUser user,
  ) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Ngừng hoạt động tài khoản',
      // The backend "delete" is a status change, not a row removal — the copy
      // must not promise a permanent deletion.
      message:
          'Tài khoản "${user.displayName}" (${user.email}) sẽ chuyển sang trạng '
          'thái ngừng hoạt động và không thể đăng nhập. Dữ liệu đơn đăng ký, '
          'đánh giá và ví vẫn được giữ lại.',
      confirmLabel: 'Ngừng hoạt động',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final error = await ref
        .read(adminUsersControllerProvider.notifier)
        .deactivate(user.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã ngừng hoạt động tài khoản.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUserDetailProvider(userId));
    final busy = ref.watch(
      adminMutationBusyProvider(adminMutationKey('deactivate-user', userId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        actions: [
          IconButton(
            onPressed: () => context.push(RouteNames.adminUserEditPath(userId)),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          AsyncData(:final value) => _UserBody(
            user: value,
            onRefresh: () async =>
                ref.invalidate(adminUserDetailProvider(userId)),
          ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () => ref.invalidate(adminUserDetailProvider(userId)),
          ),
          _ => const AppLoading(),
        },
      ),
      bottomNavigationBar: switch (state) {
        AsyncData(:final value) when value.status != AdminUserStatus.inactive =>
          AdminBottomActionBar(
            child: AppButton(
              label: 'Ngừng hoạt động tài khoản',
              icon: Icons.block_rounded,
              variant: AppButtonVariant.destructive,
              loading: busy,
              onPressed: busy
                  ? null
                  : () => _confirmDeactivate(context, ref, value),
            ),
          ),
        _ => null,
      },
    );
  }
}

class _UserBody extends StatelessWidget {
  const _UserBody({required this.user, required this.onRefresh});

  final AdminUser user;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.textSecondary,
                        ),
                        placeholder: (_, _) => const Icon(
                          Icons.person_rounded,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: AppColors.textSecondary,
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 2),
                    Text(user.email, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              AdminStatusChip(label: user.status.label, tone: user.status.tone),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const AdminSectionHeader(title: 'Vai trò'),
          AppCard(
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (user.roles.isEmpty)
                  Text('Chưa gán vai trò', style: AppTextStyles.bodySecondary),
                for (final role in user.roles)
                  AppBadge(
                    label: AdminRoles.label(role),
                    tone: AdminRoles.tone(role),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const AdminSectionHeader(title: 'Thông tin liên hệ'),
          AppCard(
            child: Column(
              children: [
                AdminInfoRow(label: 'Email', value: user.email, copyable: true),
                AdminInfoRow(label: 'Số điện thoại', value: user.phone ?? '—'),
                AdminInfoRow(
                  label: 'Ngày sinh',
                  value: DateFormatter.date(user.dateOfBirth),
                ),
              ],
            ),
          ),

          if (user.coachProfile != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const AdminSectionHeader(title: 'Hồ sơ huấn luyện viên'),
            AppCard(
              child: Column(
                children: [
                  AdminInfoRow(
                    label: 'Tiêu đề',
                    value: user.coachProfile!.headline ?? '—',
                  ),
                  AdminInfoRow(
                    label: 'Kinh nghiệm',
                    value: user.coachProfile!.experienceYears != null
                        ? '${user.coachProfile!.experienceYears} năm'
                        : '—',
                  ),
                  AdminInfoRow(
                    label: 'Đánh giá',
                    value:
                        '${user.coachProfile!.rating} '
                        '(${user.coachProfile!.totalReviews} lượt)',
                  ),
                ],
              ),
            ),
          ],

          if (user.learnerProfile?.goal != null) ...[
            const SizedBox(height: AppSpacing.lg),
            const AdminSectionHeader(title: 'Hồ sơ người tập'),
            AppCard(
              child: AdminInfoRow(
                label: 'Mục tiêu',
                value: user.learnerProfile!.goal!,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          const AdminSectionHeader(title: 'Hệ thống'),
          AppCard(
            child: Column(
              children: [
                AdminInfoRow(
                  label: 'Ngày tạo',
                  value: DateFormatter.dateTime(user.createdAt),
                ),
                AdminInfoRow(
                  label: 'Cập nhật',
                  value: DateFormatter.dateTime(user.updatedAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
