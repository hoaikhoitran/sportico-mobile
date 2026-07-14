import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_identity_line.dart';
import '../../shared/widgets/admin_paged_list_view.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/review_report.dart';
import 'review_reports_controller.dart';
import 'widgets/resolve_report_sheet.dart';

/// Reported reviews, filtered by report status.
class ReviewReportsTab extends ConsumerWidget {
  const ReviewReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewReportsControllerProvider);
    final controller = ref.read(reviewReportsControllerProvider.notifier);
    final active = controller.statusFilter;

    return AdminPagedListView<ReviewReport>(
      state: state,
      onRefresh: controller.refresh,
      onLoadMore: controller.loadMore,
      emptyIcon: Icons.flag_outlined,
      emptyTitle: switch (active) {
        ReviewReportStatus.pending => 'Không có báo cáo chờ xử lý',
        null => 'Chưa có báo cáo nào',
        final status => 'Không có báo cáo ở trạng thái "${status.label}"',
      },
      emptyMessage: active == null
          ? 'Các đánh giá bị báo cáo sẽ xuất hiện tại đây.'
          : 'Thử chọn một trạng thái khác.',
      totalLabelBuilder: (total) => '$total báo cáo',
      header: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.xs,
          ),
          children: [
            for (final (label, status) in <(String, ReviewReportStatus?)>[
              ('Tất cả', null),
              ('Chờ xử lý', ReviewReportStatus.pending),
              ('Đang xem xét', ReviewReportStatus.reviewing),
              ('Đã xử lý', ReviewReportStatus.resolved),
              ('Đã bác bỏ', ReviewReportStatus.rejected),
            ]) ...[
              ChoiceChip(
                label: Text(label),
                selected: active == status,
                onSelected: (_) => controller.setStatus(status),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
      itemBuilder: (context, report) => _ReviewReportCard(report: report),
    );
  }
}

class _ReviewReportCard extends ConsumerWidget {
  const _ReviewReportCard({required this.report});

  final ReviewReport report;

  Future<void> _resolve(BuildContext context, WidgetRef ref) async {
    final request = await showResolveReportSheet(context);
    if (request == null || !context.mounted) return;

    final error = await ref
        .read(reviewReportsControllerProvider.notifier)
        .resolve(report.id, request);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(
        context,
        request.isValid ? 'Đã xử lý báo cáo.' : 'Đã bác bỏ báo cáo.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(
      adminMutationBusyProvider(adminMutationKey('resolve-report', report.id)),
    );

    return AppCard(
      onTap: () => context.push(
        RouteNames.adminReviewReportDetailPath(report.id),
        extra: report,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminIdentityLine(
                  userId: report.reporterId,
                  prefix: 'Người báo cáo:',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AdminStatusChip(
                label: report.status.label,
                tone: report.status.tone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.reason?.isNotEmpty == true
                ? report.reason!
                : 'Không có lý do báo cáo',
            style: AppTextStyles.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (report.reviewComment != null &&
              report.reviewComment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.reviewRating != null) ...[
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.accentOrange,
                    ),
                    Text(
                      '${report.reviewRating}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Expanded(
                    child: Text(
                      report.reviewComment!,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Báo cáo ${DateFormatter.dateTime(report.createdAt)}',
            style: AppTextStyles.caption,
          ),
          if (report.status.isResolvable) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Xử lý báo cáo',
              icon: Icons.gavel_rounded,
              size: AppButtonSize.small,
              loading: busy,
              onPressed: busy ? null : () => _resolve(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
