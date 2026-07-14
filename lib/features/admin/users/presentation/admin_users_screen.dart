import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/widgets/admin_paged_list_view.dart';
import '../../shared/widgets/admin_search_field.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/admin_user.dart';
import 'admin_users_controller.dart';

/// User directory with keyword search, role and status filters.
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminUsersControllerProvider);
    final controller = ref.read(adminUsersControllerProvider.notifier);
    final filter = controller.filter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Người dùng'),
        actions: [
          if (controller.hasActiveFilters)
            TextButton(
              onPressed: controller.clearFilters,
              child: const Text('Xóa lọc'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.adminUserCreate),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tạo tài khoản'),
      ),
      body: SafeArea(
        child: AdminPagedListView<AdminUser>(
          state: state,
          onRefresh: controller.refresh,
          onLoadMore: controller.loadMore,
          emptyIcon: Icons.people_outline_rounded,
          emptyTitle: controller.hasActiveFilters
              ? 'Không tìm thấy người dùng nào'
              : 'Chưa có người dùng',
          emptyMessage: controller.hasActiveFilters
              ? 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.'
              : null,
          totalLabelBuilder: (total) => '$total người dùng',
          header: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.xs,
                  AppSpacing.screenH,
                  0,
                ),
                child: AdminSearchField(
                  hint: 'Tìm theo tên hoặc email',
                  onSearch: controller.search,
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH,
                    vertical: AppSpacing.xs,
                  ),
                  children: [
                    for (final role in AdminRoles.all) ...[
                      ChoiceChip(
                        label: Text(AdminRoles.label(role)),
                        selected: filter.role == role,
                        onSelected: (selected) =>
                            controller.setRole(selected ? role : null),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    const _ChipDivider(),
                    for (final status in AdminUserStatus.assignable) ...[
                      ChoiceChip(
                        label: Text(status.label),
                        selected: filter.status == status,
                        onSelected: (selected) =>
                            controller.setStatus(selected ? status : null),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ],
          ),
          itemBuilder: (context, user) => _UserCard(user: user),
        ),
      ),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
    child: VerticalDivider(width: 1, color: AppColors.outlineVariant),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    return AppCard(
      onTap: () => context.push(RouteNames.adminUserDetailPath(user.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const _AvatarFallback(),
                    placeholder: (_, _) => const _AvatarFallback(),
                  )
                : const _AvatarFallback(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.displayName,
                        style: AppTextStyles.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AdminStatusChip(
                      label: user.status.label,
                      tone: user.status.tone,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: AppTextStyles.bodySecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    for (final role in user.roles)
                      AppBadge(
                        label: AdminRoles.label(role),
                        tone: AdminRoles.tone(role),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tham gia ${DateFormatter.date(user.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.person_rounded,
    size: 22,
    color: AppColors.textSecondary,
  );
}
