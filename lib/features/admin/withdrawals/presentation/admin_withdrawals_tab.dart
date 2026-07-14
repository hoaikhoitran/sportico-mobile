import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/widgets/admin_identity_line.dart';
import '../../shared/widgets/admin_paged_list_view.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/withdrawal_request.dart';
import 'admin_withdrawals_controller.dart';

/// Withdrawal queue with a status filter (defaults to the pending shortcut).
class AdminWithdrawalsTab extends ConsumerWidget {
  const AdminWithdrawalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminWithdrawalsControllerProvider);
    final controller = ref.read(adminWithdrawalsControllerProvider.notifier);
    final active = controller.statusFilter;

    return AdminPagedListView<WithdrawalRequest>(
      state: state,
      onRefresh: controller.refresh,
      onLoadMore: controller.loadMore,
      emptyIcon: Icons.account_balance_wallet_outlined,
      emptyTitle: switch (active) {
        null => 'Chưa có yêu cầu rút tiền',
        WithdrawalStatus.pending => 'Không có yêu cầu chờ duyệt',
        final status => 'Không có yêu cầu ở trạng thái "${status.label}"',
      },
      emptyMessage: active == null
          ? 'Yêu cầu rút tiền của huấn luyện viên sẽ xuất hiện tại đây.'
          : 'Thử chọn một trạng thái khác.',
      totalLabelBuilder: (total) => '$total yêu cầu',
      header: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.xs,
          ),
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: active == null,
              onSelected: (_) => controller.setStatus(null),
            ),
            const SizedBox(width: AppSpacing.xs),
            for (final status in WithdrawalStatus.filterable) ...[
              ChoiceChip(
                label: Text(status.label),
                selected: active == status,
                onSelected: (_) => controller.setStatus(status),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ),
      itemBuilder: (context, withdrawal) =>
          _WithdrawalCard(withdrawal: withdrawal),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({required this.withdrawal});

  final WithdrawalRequest withdrawal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () =>
          context.push(RouteNames.adminWithdrawalDetailPath(withdrawal.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminIdentityLine(
                  userId: withdrawal.coachId,
                  prefix: 'HLV',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AdminStatusChip(
                label: withdrawal.status.label,
                tone: withdrawal.status.tone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(withdrawal.amountLabel, style: AppTextStyles.price),
              ),
              Text(
                DateFormatter.date(withdrawal.createdAt),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (withdrawal.payOsPayoutStatus != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'PayOS: ${withdrawal.payOsPayoutStatus}',
              style: AppTextStyles.caption,
            ),
          ],
          if (withdrawal.paidAt != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Thanh toán ${DateFormatter.dateTime(withdrawal.paidAt)}',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}
