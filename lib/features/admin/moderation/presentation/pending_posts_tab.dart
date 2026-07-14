import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_identity_line.dart';
import '../../shared/widgets/admin_paged_list_view.dart';
import '../../shared/widgets/admin_search_field.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/admin_post.dart';
import 'pending_posts_controller.dart';
import 'widgets/moderation_action_bar.dart';

/// Queue of coach posts waiting for moderation.
class PendingPostsTab extends ConsumerWidget {
  const PendingPostsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingPostsControllerProvider);
    final controller = ref.read(pendingPostsControllerProvider.notifier);

    return AdminPagedListView<AdminPost>(
      state: state,
      onRefresh: controller.refresh,
      onLoadMore: controller.loadMore,
      emptyIcon: Icons.article_outlined,
      emptyTitle: controller.hasActiveFilters
          ? 'Không tìm thấy bài viết nào'
          : 'Không có bài viết chờ duyệt',
      emptyMessage: controller.hasActiveFilters
          ? 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.'
          : 'Mọi bài viết đã được xử lý.',
      totalLabelBuilder: (total) => '$total bài viết chờ duyệt',
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.xs,
          AppSpacing.screenH,
          AppSpacing.xs,
        ),
        child: AdminSearchField(
          hint: 'Tìm theo tiêu đề bài viết',
          onSearch: controller.search,
        ),
      ),
      itemBuilder: (context, post) => _PendingPostCard(post: post),
    );
  }
}

class _PendingPostCard extends ConsumerWidget {
  const _PendingPostCard({required this.post});

  final AdminPost post;

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Duyệt bài viết',
      message:
          'Bài viết "${post.title}" sẽ được đăng công khai. Bạn có chắc chắn?',
      confirmLabel: 'Phê duyệt',
    );
    if (!confirmed || !context.mounted) return;

    final error = await ref
        .read(pendingPostsControllerProvider.notifier)
        .approve(post.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã duyệt bài viết.');
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showAdminRejectReasonSheet(
      context,
      title: 'Từ chối bài viết',
      description: 'Lý do giúp huấn luyện viên chỉnh sửa và gửi lại.',
      label: 'Lý do từ chối',
      hint: 'Ví dụ: nội dung không phù hợp, hình ảnh kém chất lượng…',
      submitLabel: 'Từ chối',
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;

    final error = await ref
        .read(pendingPostsControllerProvider.notifier)
        .reject(post.id, reason);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã từ chối bài viết.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;

    return AppCard(
      onTap: () =>
          context.push(RouteNames.adminPostDetailPath(post.id), extra: post),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminIdentityLine(userId: post.coachId, prefix: 'HLV'),
              ),
              const SizedBox(width: AppSpacing.xs),
              AdminStatusChip(label: post.status.label, tone: post.status.tone),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumbnail != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: CachedNetworkImage(
                    imageUrl: thumbnail,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    // A bad URL must degrade to a placeholder, never to a
                    // broken/oversized image box.
                    errorWidget: (_, _, _) => const _ImageFallback(),
                    placeholder: (_, _) => const _ImageFallback(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: AppTextStyles.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (post.description != null &&
                        post.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        post.description!,
                        style: AppTextStyles.bodySecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(post.priceLabel, style: AppTextStyles.price),
              const Spacer(),
              Text(
                'Gửi ${DateFormatter.date(post.createdAt)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppSpacing.xs),
          ModerationActionBar(
            dense: true,
            approveKey: adminMutationKey('approve-post', post.id),
            rejectKey: adminMutationKey('reject-post', post.id),
            onApprove: () => _approve(context, ref),
            onReject: () => _reject(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.surfaceMuted,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 20,
        color: AppColors.textSecondary,
      ),
    );
  }
}
