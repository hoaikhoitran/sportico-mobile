import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../training_packages/data/models/training_package.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_identity_line.dart';
import '../../shared/widgets/admin_info_row.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../../shared/widgets/admin_status_chip.dart';
import 'pending_packages_controller.dart';
import 'widgets/moderation_action_bar.dart';

/// Full package under review, with the fixed schedule the coach submitted.
///
/// The admin API exposes no `GET /training-packages/{id}`, so the package is
/// handed over from the queue (`extra`) and re-read from the loaded list when
/// the screen is rebuilt.
class AdminPackageDetailScreen extends ConsumerWidget {
  const AdminPackageDetailScreen({
    super.key,
    required this.packageId,
    this.initial,
  });

  final String packageId;
  final TrainingPackage? initial;

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    TrainingPackage package,
  ) async {
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
      return;
    }
    AppSnackBar.success(context, 'Đã duyệt gói tập.');
    Navigator.of(context).pop();
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    TrainingPackage package,
  ) async {
    final reason = await showAdminRejectReasonSheet(
      context,
      title: 'Từ chối gói tập',
      description: 'Lý do sẽ được gửi tới huấn luyện viên.',
      label: 'Lý do từ chối',
      hint: 'Ví dụ: lịch tập chưa hợp lý, mô tả thiếu thông tin…',
      submitLabel: 'Từ chối',
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;

    final error = await ref
        .read(pendingPackagesControllerProvider.notifier)
        .reject(package.id, reason);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    AppSnackBar.success(context, 'Đã từ chối gói tập.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the screen in sync with the queue after a refresh.
    ref.watch(pendingPackagesControllerProvider);
    final package =
        ref
            .read(pendingPackagesControllerProvider.notifier)
            .findById(packageId) ??
        initial;

    if (package == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gói tập')),
        body: const _MissingItem(
          message: 'Gói tập không còn trong hàng chờ duyệt.',
        ),
      );
    }

    final isPending = package.status == PackageStatus.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt gói tập')),
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
                  child: Text(package.title, style: AppTextStyles.screenTitle),
                ),
                const SizedBox(width: AppSpacing.xs),
                AdminStatusChip(
                  label: package.status.label,
                  tone: package.status.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppCard(
              child: AdminIdentityLine(
                userId: package.coachId,
                prefix: 'HLV',
                showEmail: true,
                avatarSize: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const AdminSectionHeader(title: 'Thông tin gói tập'),
            AppCard(
              child: Column(
                children: [
                  AdminInfoRow(label: 'Môn thể thao', value: package.sportName),
                  AdminInfoRow(
                    label: 'Giá',
                    value: package.priceLabel,
                    emphasize: true,
                  ),
                  AdminInfoRow(
                    label: 'Số buổi',
                    value: '${package.sessionCount} buổi',
                  ),
                  AdminInfoRow(
                    label: 'Thời lượng',
                    value: '${package.durationDays} ngày',
                  ),
                  AdminInfoRow(
                    label: 'Thời gian',
                    value:
                        '${DateFormatter.date(package.startDate)} – '
                        '${DateFormatter.date(package.endDate)}',
                  ),
                  AdminInfoRow(
                    label: 'Hình thức',
                    value: package.isOnline ? 'Online' : 'Trực tiếp',
                  ),
                  AdminInfoRow(
                    label: 'Địa điểm',
                    value: package.location ?? '—',
                  ),
                  AdminInfoRow(
                    label: 'Trình độ',
                    value: PackageLabels.level(package.level),
                  ),
                  AdminInfoRow(
                    label: 'Mục tiêu',
                    value: PackageLabels.goal(package.goalType),
                  ),
                  AdminInfoRow(
                    label: 'Ngày gửi',
                    value: DateFormatter.dateTime(package.createdAt),
                  ),
                ],
              ),
            ),

            if (package.description != null &&
                package.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const AdminSectionHeader(title: 'Mô tả'),
              AppCard(
                child: Text(package.description!, style: AppTextStyles.body),
              ),
            ],

            if (package.sessions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AdminSectionHeader(
                title: 'Lịch tập',
                subtitle: '${package.sessions.length} buổi đã lên lịch',
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    for (final session in package.sessions)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.accentBlueSoft,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                              ),
                              child: Text(
                                '${session.sessionNumber}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatter.weekdayDate(
                                      session.startTime,
                                    ),
                                    style: AppTextStyles.body,
                                  ),
                                  Text(
                                    '${DateFormatter.timeRange(session.startTime, session.endTime)}'
                                    ' · Tối đa ${session.maxParticipants} người',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: isPending
          ? AdminBottomActionBar(
              child: ModerationActionBar(
                approveKey: adminMutationKey('approve-package', package.id),
                rejectKey: adminMutationKey('reject-package', package.id),
                onApprove: () => _approve(context, ref, package),
                onReject: () => _reject(context, ref, package),
              ),
            )
          : null,
    );
  }
}

class _MissingItem extends StatelessWidget {
  const _MissingItem({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại danh sách'),
            ),
          ],
        ),
      ),
    );
  }
}
