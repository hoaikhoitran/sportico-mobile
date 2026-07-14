import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_identity_line.dart';
import '../../shared/widgets/admin_info_row.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/admin_post.dart';
import 'pending_posts_controller.dart';
import 'widgets/moderation_action_bar.dart';

/// Full post under review: complete text plus every attached image.
class AdminPostDetailScreen extends ConsumerWidget {
  const AdminPostDetailScreen({super.key, required this.postId, this.initial});

  final String postId;
  final AdminPost? initial;

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    AdminPost post,
  ) async {
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
      return;
    }
    AppSnackBar.success(context, 'Đã duyệt bài viết.');
    Navigator.of(context).pop();
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    AdminPost post,
  ) async {
    final reason = await showAdminRejectReasonSheet(
      context,
      title: 'Từ chối bài viết',
      description: 'Lý do giúp huấn luyện viên chỉnh sửa và gửi lại.',
      label: 'Lý do từ chối',
      submitLabel: 'Từ chối',
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;

    final error = await ref
        .read(pendingPostsControllerProvider.notifier)
        .reject(post.id, reason);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    AppSnackBar.success(context, 'Đã từ chối bài viết.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pendingPostsControllerProvider);
    final post =
        ref.read(pendingPostsControllerProvider.notifier).findById(postId) ??
        initial;

    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài viết')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'Bài viết không còn trong hàng chờ duyệt.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt bài viết')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.xl,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(post.title, style: AppTextStyles.screenTitle),
                ),
                const SizedBox(width: AppSpacing.xs),
                AdminStatusChip(
                  label: post.status.label,
                  tone: post.status.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppCard(
              child: AdminIdentityLine(
                userId: post.coachId,
                prefix: 'HLV',
                showEmail: true,
                avatarSize: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const AdminSectionHeader(title: 'Thông tin bài viết'),
            AppCard(
              child: Column(
                children: [
                  AdminInfoRow(label: 'Môn thể thao', value: post.sportName),
                  AdminInfoRow(
                    label: 'Giá',
                    value: post.priceLabel,
                    emphasize: true,
                  ),
                  AdminInfoRow(
                    label: 'Hình thức',
                    value: post.isOnline ? 'Online' : 'Trực tiếp',
                  ),
                  AdminInfoRow(label: 'Địa điểm', value: post.location ?? '—'),
                  AdminInfoRow(
                    label: 'Ngày gửi',
                    value: DateFormatter.dateTime(post.createdAt),
                  ),
                  AdminInfoRow(
                    label: 'Cập nhật',
                    value: DateFormatter.dateTime(post.updatedAt),
                  ),
                ],
              ),
            ),

            if (post.description != null && post.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const AdminSectionHeader(title: 'Nội dung'),
              AppCard(
                child: Text(post.description!, style: AppTextStyles.body),
              ),
            ],

            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AdminSectionHeader(
                title: 'Hình ảnh',
                subtitle: '${post.imageUrls.length} ảnh đính kèm',
              ),
              for (final url in post.imageUrls) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    // Never render an invalid URL as an uncontrolled widget.
                    errorWidget: (_, _, _) => const _BrokenImage(),
                    placeholder: (_, _) => const _ImagePlaceholder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: post.status.isModeratable
          ? AdminBottomActionBar(
              child: ModerationActionBar(
                approveKey: adminMutationKey('approve-post', post.id),
                rejectKey: adminMutationKey('reject-post', post.id),
                onApprove: () => _approve(context, ref, post),
                onReject: () => _reject(context, ref, post),
              ),
            )
          : null,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    color: AppColors.surfaceMuted,
    alignment: Alignment.center,
    child: const CircularProgressIndicator(strokeWidth: 2),
  );
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    color: AppColors.surfaceMuted,
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.xxs),
        Text('Không tải được ảnh', style: AppTextStyles.caption),
      ],
    ),
  );
}
