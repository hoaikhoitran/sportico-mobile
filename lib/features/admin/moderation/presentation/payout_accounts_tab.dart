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
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/coach_payout_account.dart';
import 'payout_accounts_controller.dart';
import 'widgets/moderation_action_bar.dart';

/// Queue of coach payout accounts waiting for verification.
///
/// Account numbers are masked here; the full number is only revealed on the
/// detail screen, where the admin actually needs it to verify the account.
class PayoutAccountsTab extends ConsumerWidget {
  const PayoutAccountsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(payoutAccountsControllerProvider);
    final controller = ref.read(payoutAccountsControllerProvider.notifier);

    return AdminPagedListView<CoachPayoutAccount>(
      state: state,
      onRefresh: controller.refresh,
      onLoadMore: controller.loadMore,
      emptyIcon: Icons.account_balance_outlined,
      emptyTitle: 'Không có tài khoản chờ xác minh',
      emptyMessage: 'Mọi tài khoản nhận tiền đã được xử lý.',
      totalLabelBuilder: (total) => '$total tài khoản chờ xác minh',
      itemBuilder: (context, account) => _PayoutAccountCard(account: account),
    );
  }
}

class _PayoutAccountCard extends ConsumerWidget {
  const _PayoutAccountCard({required this.account});

  final CoachPayoutAccount account;

  Future<void> _verify(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Xác minh tài khoản',
      message:
          'Xác nhận tài khoản ${account.bankName ?? ''} '
          '${account.maskedAccountNumber} thuộc về huấn luyện viên này? '
          'Sau khi xác minh, hệ thống có thể chi trả tiền rút về tài khoản này.',
      confirmLabel: 'Xác minh',
    );
    if (!confirmed || !context.mounted) return;

    final error = await ref
        .read(payoutAccountsControllerProvider.notifier)
        .verify(account.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã xác minh tài khoản nhận tiền.');
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final note = await showAdminRejectReasonSheet(
      context,
      title: 'Từ chối tài khoản',
      description: 'Ghi chú giúp huấn luyện viên cập nhật lại thông tin.',
      label: 'Ghi chú',
      hint: 'Ví dụ: tên chủ tài khoản không khớp với hồ sơ…',
      submitLabel: 'Từ chối',
      // RejectCoachPayoutAccountRequest.Note is optional on the backend.
      reasonRequired: false,
    );
    if (note == null || !context.mounted) return;

    final error = await ref
        .read(payoutAccountsControllerProvider.notifier)
        .reject(account.id, note);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã từ chối tài khoản nhận tiền.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () => context.push(
        RouteNames.adminPayoutAccountDetailPath(account.id),
        extra: account,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminIdentityLine(
                  userId: account.coachId,
                  prefix: 'HLV',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AdminStatusChip(
                label: account.status.label,
                tone: account.status.tone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            account.bankName ?? 'Ngân hàng chưa xác định',
            style: AppTextStyles.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${account.maskedAccountNumber} · '
            '${account.bankAccountHolder ?? '—'}',
            style: AppTextStyles.bodySecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Gửi ${DateFormatter.date(account.createdAt)}',
            style: AppTextStyles.caption,
          ),
          if (account.status.isPending) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppSpacing.xs),
            ModerationActionBar(
              dense: true,
              approveLabel: 'Xác minh',
              approveKey: adminMutationKey('verify-payout-account', account.id),
              rejectKey: adminMutationKey('reject-payout-account', account.id),
              onApprove: () => _verify(context, ref),
              onReject: () => _reject(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
