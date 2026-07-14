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
import '../../../training_packages/data/models/training_package.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_identity_line.dart';
import '../../shared/widgets/admin_paged_list_view.dart';
import '../../shared/widgets/admin_search_field.dart';
import 'pending_packages_controller.dart';
import 'widgets/moderation_action_bar.dart';

/// Queue of training packages waiting for approval.
class PendingPackagesTab extends ConsumerWidget {
  const PendingPackagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingPackagesControllerProvider);
    final controller = ref.read(pendingPackagesControllerProvider.notifier);

    return AdminPagedListView<TrainingPackage>(
      state: state,
      onRefresh: controller.refresh,
      onLoadMore: controller.loadMore,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: controller.hasActiveFilters
          ? 'Không tìm thấy gói tập nào'
          : 'Không có gói tập chờ duyệt',
      emptyMessage: controller.hasActiveFilters
          ? 'Thử từ khóa khác hoặc xóa bộ lọc đang áp dụng.'
          : 'Mọi gói tập đã được xử lý.',
      totalLabelBuilder: (total) => '$total gói tập chờ duyệt',
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.xs,
          AppSpacing.screenH,
          AppSpacing.xs,
        ),
        child: AdminSearchField(
          hint: 'Tìm theo tên gói tập',
          onSearch: controller.search,
        ),
      ),
      itemBuilder: (context, package) => _PendingPackageCard(package: package),
    );
  }
}

class _PendingPackageCard extends ConsumerWidget {
  const _PendingPackageCard({required this.package});

  final TrainingPackage package;

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Duyệt gói tập',
      message:
          'Gói "${package.title}" sẽ được mở bán cho người tập. Bạn có chắc chắn?',
      confirmLabel: 'Phê duyệt',
    );
    if (!confirmed || !context.mounted) return;

    final error = await ref
        .read(pendingPackagesControllerProvider.notifier)
        .approve(package.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã duyệt gói tập.');
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showAdminRejectReasonSheet(
      context,
      title: 'Từ chối gói tập',
      description: 'Lý do sẽ được gửi tới huấn luyện viên.',
      label: 'Lý do từ chối',
      hint: 'Ví dụ: lịch tập chưa hợp lý, mô tả thiếu thông tin…',
      submitLabel: 'Từ chối',
    );
    // Backend rule: RejectTrainingPackageRequest.Reason is NotEmpty.
    if (reason == null || reason.isEmpty || !context.mounted) return;

    final error = await ref
        .read(pendingPackagesControllerProvider.notifier)
        .reject(package.id, reason);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã từ chối gói tập.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () => context.push(
        RouteNames.adminPackageDetailPath(package.id),
        extra: package,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminIdentityLine(userId: package.coachId, prefix: 'HLV'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            package.title,
            style: AppTextStyles.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${package.sportName} · ${package.sessionCount} buổi · '
            '${package.isOnline ? 'Online' : package.location ?? 'Trực tiếp'}',
            style: AppTextStyles.bodySecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(package.priceLabel, style: AppTextStyles.price),
              const Spacer(),
              Text(
                'Gửi ${DateFormatter.date(package.createdAt)}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.divider),
          const SizedBox(height: AppSpacing.xs),
          ModerationActionBar(
            dense: true,
            approveKey: adminMutationKey('approve-package', package.id),
            rejectKey: adminMutationKey('reject-package', package.id),
            onApprove: () => _approve(context, ref),
            onReject: () => _reject(context, ref),
          ),
        ],
      ),
    );
  }
}
