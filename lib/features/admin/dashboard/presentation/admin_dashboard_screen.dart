import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../shared/widgets/admin_metric_card.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../data/models/admin_dashboard.dart';
import 'admin_dashboard_controller.dart';

/// Admin home: KPIs for the selected period plus shortcuts into the queues.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);
    final controller = ref.read(adminDashboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan')),
      body: SafeArea(
        child: Column(
          children: [
            _PeriodFilterBar(
              active: controller.filter,
              onSelect: controller.setFilter,
            ),
            Expanded(
              child: switch (state) {
                AsyncData(:final value) => _DashboardBody(
                  dashboard: value,
                  periodLabel: controller.filter.label,
                  onRefresh: controller.refresh,
                ),
                AsyncError(:final error) => AppErrorState(
                  error: error is ApiError ? error : null,
                  onRetry: controller.refresh,
                ),
                _ => const AppSkeletonList(showDayHeaders: false),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodFilterBar extends StatelessWidget {
  const _PeriodFilterBar({required this.active, required this.onSelect});

  final DashboardFilter active;
  final ValueChanged<DashboardFilter> onSelect;

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      currentDate: now,
      helpText: 'Chọn khoảng thời gian',
      saveText: 'Áp dụng',
    );
    if (picked == null) return;
    onSelect(
      DashboardFilter.range(
        picked.start,
        // Include the whole end day.
        DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        '${DateFormatter.date(picked.start)} – ${DateFormatter.date(picked.end)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custom =
        !active.isAllTime &&
        active.label != '7 ngày qua' &&
        active.label != '30 ngày qua';

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenH,
          vertical: AppSpacing.xs,
        ),
        children: [
          ChoiceChip(
            label: const Text('Toàn thời gian'),
            selected: active.isAllTime,
            onSelected: (_) => onSelect(DashboardFilter.allTime),
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            label: const Text('7 ngày'),
            selected: active.label == '7 ngày qua',
            onSelected: (_) =>
                onSelect(DashboardFilter.lastDays(7, '7 ngày qua')),
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            label: const Text('30 ngày'),
            selected: active.label == '30 ngày qua',
            onSelected: (_) =>
                onSelect(DashboardFilter.lastDays(30, '30 ngày qua')),
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            avatar: const Icon(Icons.date_range_rounded, size: 16),
            label: Text(custom ? active.label : 'Tùy chọn'),
            selected: custom,
            onSelected: (_) => _pickRange(context),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.dashboard,
    required this.periodLabel,
    required this.onRefresh,
  });

  final AdminDashboard dashboard;
  final String periodLabel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.xs,
          AppSpacing.screenH,
          AppSpacing.xxl,
        ),
        children: [
          Text('Kỳ báo cáo: $periodLabel', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),

          const AdminSectionHeader(
            title: 'Doanh thu',
            subtitle: 'Tính trên các đơn đã thanh toán',
          ),
          _MetricGrid(
            children: [
              AdminMetricCard(
                icon: Icons.payments_rounded,
                label: 'Tổng doanh thu',
                value: dashboard.grossRevenueLabel,
                tint: AppColors.accentOrangeSoft,
                iconColor: AppColors.accentOrange,
              ),
              AdminMetricCard(
                icon: Icons.account_balance_rounded,
                label: 'Hoa hồng nền tảng',
                value: dashboard.platformFeeRevenueLabel,
                tint: AppColors.successSoft,
                iconColor: AppColors.success,
              ),
              AdminMetricCard(
                icon: Icons.savings_rounded,
                label: 'Phải trả huấn luyện viên',
                value: dashboard.coachPayableLabel,
              ),
              AdminMetricCard(
                icon: Icons.north_east_rounded,
                label: 'Đã chi trả rút tiền',
                value: dashboard.totalWithdrawnPaidLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const AdminSectionHeader(title: 'Người dùng'),
          _MetricGrid(
            children: [
              AdminMetricCard(
                icon: Icons.group_rounded,
                label: 'Tổng người dùng',
                value: '${dashboard.totalUsers}',
              ),
              AdminMetricCard(
                icon: Icons.sports_rounded,
                label: 'Huấn luyện viên',
                value: '${dashboard.totalCoaches}',
              ),
              AdminMetricCard(
                icon: Icons.directions_run_rounded,
                label: 'Người tập',
                value: '${dashboard.totalLearners}',
              ),
              AdminMetricCard(
                icon: Icons.inventory_2_rounded,
                label: 'Gói tập đang mở bán',
                value: '${dashboard.publishedPackages}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const AdminSectionHeader(title: 'Đơn đăng ký'),
          _MetricGrid(
            children: [
              AdminMetricCard(
                icon: Icons.receipt_long_rounded,
                label: 'Tổng đơn',
                value: '${dashboard.totalBookings}',
              ),
              AdminMetricCard(
                icon: Icons.play_circle_rounded,
                label: 'Đang hoạt động',
                value: '${dashboard.activeBookings}',
              ),
              AdminMetricCard(
                icon: Icons.check_circle_rounded,
                label: 'Hoàn thành',
                value: '${dashboard.completedBookings}',
                tint: AppColors.successSoft,
                iconColor: AppColors.success,
              ),
              AdminMetricCard(
                icon: Icons.cancel_rounded,
                label: 'Đã hủy',
                value: '${dashboard.cancelledBookings}',
                tint: AppColors.dangerSoft,
                iconColor: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          AdminSectionHeader(
            title: 'Yêu cầu rút tiền',
            trailing: TextButton(
              onPressed: () => context.go(RouteNames.adminFinance),
              child: const Text('Xử lý'),
            ),
          ),
          _MetricGrid(
            children: [
              AdminMetricCard(
                icon: Icons.hourglass_top_rounded,
                label: 'Chờ duyệt',
                value: '${dashboard.pendingWithdrawals}',
                tint: AppColors.warningSoft,
                iconColor: AppColors.warning,
                onTap: () => context.go(RouteNames.adminFinance),
              ),
              AdminMetricCard(
                icon: Icons.sync_rounded,
                label: 'Đang chuyển tiền',
                value: '${dashboard.processingWithdrawals}',
                onTap: () => context.go(RouteNames.adminFinance),
              ),
              AdminMetricCard(
                icon: Icons.task_alt_rounded,
                label: 'Đã thanh toán',
                value: '${dashboard.paidWithdrawals}',
                tint: AppColors.successSoft,
                iconColor: AppColors.success,
                onTap: () => context.go(RouteNames.adminFinance),
              ),
              AdminMetricCard(
                icon: Icons.error_rounded,
                label: 'Thất bại',
                value: '${dashboard.failedWithdrawals}',
                tint: AppColors.dangerSoft,
                iconColor: AppColors.danger,
                onTap: () => context.go(RouteNames.adminFinance),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const AdminSectionHeader(title: 'Lối tắt'),
          _ShortcutTile(
            icon: Icons.fact_check_rounded,
            title: 'Hàng chờ phê duyệt',
            subtitle: 'Gói tập, bài viết, tài khoản nhận tiền, báo cáo',
            onTap: () => context.go(RouteNames.adminApprovals),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ShortcutTile(
            icon: Icons.manage_accounts_rounded,
            title: 'Quản lý người dùng',
            subtitle: 'Tìm kiếm, tạo, chỉnh sửa tài khoản',
            onTap: () => context.go(RouteNames.adminUsers),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ShortcutTile(
            icon: Icons.percent_rounded,
            title: 'Tỷ lệ hoa hồng',
            subtitle: 'Cấu hình hoa hồng nền tảng',
            onTap: () => context.push(RouteNames.adminCommission),
          ),
        ],
      ),
    );
  }
}

/// Responsive KPI grid: 2 columns on a phone, more on a tablet.
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        const gap = AppSpacing.sm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.accentBlueSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle),
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
