import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../shared/widgets/admin_info_row.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/review_report.dart';
import 'review_reports_controller.dart';
import 'widgets/moderation_action_bar.dart';
import 'widgets/resolve_report_sheet.dart';

/// A reported review: who reported it, why, and the review itself.
class AdminReviewReportDetailScreen extends ConsumerWidget {
  const AdminReviewReportDetailScreen({
    super.key,
    required this.reportId,
    this.initial,
  });

  final String reportId;
  final ReviewReport? initial;

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    ReviewReport report,
  ) async {
    final request = await showResolveReportSheet(context);
    if (request == null || !context.mounted) return;

    final error = await ref
        .read(reviewReportsControllerProvider.notifier)
        .resolve(report.id, request);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    AppSnackBar.success(
      context,
      request.isValid ? 'Đã xử lý báo cáo.' : 'Đã bác bỏ báo cáo.',
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reviewReportsControllerProvider);
    final report =
        ref.read(reviewReportsControllerProvider.notifier).findById(reportId) ??
        initial;

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo cáo đánh giá')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'Không tìm thấy báo cáo trong danh sách hiện tại.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final busy = ref.watch(
      adminMutationBusyProvider(adminMutationKey('resolve-report', report.id)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo đánh giá')),
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
                  child: Text(
                    report.reason?.isNotEmpty == true
                        ? report.reason!
                        : 'Không có lý do báo cáo',
                    style: AppTextStyles.screenTitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AdminStatusChip(
                  label: report.status.label,
                  tone: report.status.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            const AdminSectionHeader(title: 'Người báo cáo'),
            AppCard(
              child: AdminIdentityLine(
                userId: report.reporterId,
                showEmail: true,
                avatarSize: 40,
              ),
            ),

            if (report.description != null &&
                report.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const AdminSectionHeader(title: 'Mô tả từ người báo cáo'),
              AppCard(
                child: Text(report.description!, style: AppTextStyles.body),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            const AdminSectionHeader(title: 'Đánh giá bị báo cáo'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (report.reviewCoachId != null)
                    AdminIdentityLine(
                      userId: report.reviewCoachId!,
                      prefix: 'HLV',
                    ),
                  if (report.reviewLearnerId != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AdminIdentityLine(
                      userId: report.reviewLearnerId!,
                      prefix: 'Người đánh giá:',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  if (report.reviewRating != null)
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            i <= report.reviewRating!
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: AppColors.accentOrange,
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${report.reviewRating}/5',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ],
                    ),
                  if (report.reviewComment != null &&
                      report.reviewComment!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(report.reviewComment!, style: AppTextStyles.body),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  AdminInfoRow(
                    label: 'Trạng thái đánh giá',
                    value: ReviewStatusLabels.label(report.reviewStatus),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            const AdminSectionHeader(title: 'Xử lý'),
            AppCard(
              child: Column(
                children: [
                  AdminInfoRow(
                    label: 'Ngày báo cáo',
                    value: DateFormatter.dateTime(report.createdAt),
                  ),
                  AdminInfoRow(
                    label: 'Hành động',
                    value: ReviewReportActions.label(report.actionTaken),
                  ),
                  AdminInfoRow(
                    label: 'Ngày xử lý',
                    value: DateFormatter.dateTime(report.handledAt),
                  ),
                  AdminInfoRow(
                    label: 'Ghi chú xử lý',
                    value: report.resolutionNote ?? '—',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: report.status.isResolvable
          ? AdminBottomActionBar(
              child: AppButton(
                label: 'Xử lý báo cáo',
                icon: Icons.gavel_rounded,
                loading: busy,
                onPressed: busy ? null : () => _resolve(context, ref, report),
              ),
            )
          : null,
    );
  }
}
