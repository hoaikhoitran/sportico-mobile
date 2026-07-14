import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../moderation/presentation/widgets/moderation_action_bar.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_dialogs.dart';
import '../../shared/widgets/admin_identity_line.dart';
import '../../shared/widgets/admin_info_row.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/withdrawal_request.dart';
import 'admin_withdrawals_controller.dart';

/// One withdrawal request, with only the actions its status actually allows
/// (see [WithdrawalActions]).
class AdminWithdrawalDetailScreen extends ConsumerWidget {
  const AdminWithdrawalDetailScreen({super.key, required this.withdrawalId});

  final String withdrawalId;

  AdminWithdrawalDetailController _controller(WidgetRef ref) =>
      ref.read(adminWithdrawalDetailProvider(withdrawalId).notifier);

  Future<void> _handle(
    BuildContext context,
    Future<ApiError?> action,
    String successMessage,
  ) async {
    final error = await action;
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, successMessage);
    }
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    WithdrawalRequest w,
  ) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Duyệt yêu cầu rút tiền',
      message:
          'Duyệt khoản rút ${w.amountLabel}. Hệ thống sẽ chuyển tiền về tài '
          'khoản đã xác minh của huấn luyện viên. Thao tác này không thể hoàn tác.',
      confirmLabel: 'Phê duyệt',
    );
    if (!confirmed || !context.mounted) return;
    await _handle(
      context,
      _controller(ref).approve(),
      'Đã duyệt yêu cầu rút tiền.',
    );
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    WithdrawalRequest w,
  ) async {
    final note = await showAdminRejectReasonSheet(
      context,
      title: 'Từ chối yêu cầu rút tiền',
      description:
          'Số tiền ${w.amountLabel} sẽ được hoàn lại vào số dư khả dụng của '
          'huấn luyện viên.',
      label: 'Ghi chú',
      submitLabel: 'Từ chối',
      // RejectWithdrawalRequest.adminNote is optional on the backend.
      reasonRequired: false,
    );
    if (note == null || !context.mounted) return;
    await _handle(
      context,
      _controller(ref).reject(note),
      'Đã từ chối yêu cầu rút tiền.',
    );
  }

  Future<void> _markPaid(
    BuildContext context,
    WidgetRef ref,
    WithdrawalRequest w,
  ) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Đánh dấu đã thanh toán',
      message:
          'Xác nhận đã chuyển ${w.amountLabel} cho huấn luyện viên bằng hình '
          'thức thủ công? Số dư tạm giữ sẽ được trừ và không thể hoàn tác.',
      confirmLabel: 'Đã thanh toán',
    );
    if (!confirmed || !context.mounted) return;
    await _handle(
      context,
      _controller(ref).markPaid(),
      'Đã đánh dấu thanh toán.',
    );
  }

  Future<void> _retry(
    BuildContext context,
    WidgetRef ref,
    WithdrawalRequest w,
  ) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Thử thanh toán lại',
      message:
          'Tạo lại lệnh chi ${w.amountLabel} qua PayOS. Số tiền sẽ được giữ lại '
          'từ số dư khả dụng.',
      confirmLabel: 'Thử lại',
    );
    if (!confirmed || !context.mounted) return;
    await _handle(
      context,
      _controller(ref).retryPayout(),
      'Đã gửi lại lệnh thanh toán.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminWithdrawalDetailProvider(withdrawalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu rút tiền'),
        actions: [
          IconButton(
            onPressed: () => context.push(
              RouteNames.adminWithdrawalReceiptPath(withdrawalId),
            ),
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Xem biên nhận',
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          AsyncData(:final value) => _WithdrawalBody(
            withdrawal: value,
            onRefresh: _controller(ref).refresh,
          ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: _controller(ref).refresh,
          ),
          _ => const AppLoading(),
        },
      ),
      bottomNavigationBar: switch (state) {
        AsyncData(:final value) when WithdrawalActions.hasAny(value) =>
          AdminBottomActionBar(
            child: _WithdrawalActionButtons(
              withdrawal: value,
              onApprove: () => _approve(context, ref, value),
              onReject: () => _reject(context, ref, value),
              onMarkPaid: () => _markPaid(context, ref, value),
              onRetry: () => _retry(context, ref, value),
              onRefreshPayout: () => _handle(
                context,
                _controller(ref).refreshPayoutStatus(),
                'Đã cập nhật trạng thái thanh toán.',
              ),
            ),
          ),
        _ => null,
      },
    );
  }
}

class _WithdrawalBody extends StatelessWidget {
  const _WithdrawalBody({required this.withdrawal, required this.onRefresh});

  final WithdrawalRequest withdrawal;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  withdrawal.amountLabel,
                  style: AppTextStyles.displayTitle,
                ),
              ),
              AdminStatusChip(
                label: withdrawal.status.label,
                tone: withdrawal.status.tone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          AppCard(
            child: AdminIdentityLine(
              userId: withdrawal.coachId,
              prefix: 'HLV',
              showEmail: true,
              avatarSize: 40,
            ),
          ),

          if (withdrawal.failureReason != null &&
              withdrawal.failureReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Lý do thất bại: ${withdrawal.failureReason}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          const AdminSectionHeader(title: 'Thanh toán'),
          AppCard(
            child: Column(
              children: [
                AdminInfoRow(
                  label: 'Trạng thái PayOS',
                  value: withdrawal.payOsPayoutStatus ?? '—',
                ),
                AdminInfoRow(
                  label: 'Mã lệnh chi',
                  value: withdrawal.payOsPayoutId ?? '—',
                  copyable: true,
                ),
                AdminInfoRow(
                  label: 'Mã tham chiếu',
                  value: withdrawal.payOsReferenceId ?? '—',
                  copyable: true,
                ),
                AdminInfoRow(
                  label: 'Tài khoản nhận',
                  value: withdrawal.coachPayoutAccountId != null
                      ? 'Đã liên kết'
                      : 'Chưa liên kết',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          const AdminSectionHeader(title: 'Diễn biến'),
          AppCard(
            child: Column(
              children: [
                AdminInfoRow(
                  label: 'Ngày yêu cầu',
                  value: DateFormatter.dateTime(withdrawal.createdAt),
                ),
                AdminInfoRow(
                  label: 'Ngày duyệt',
                  value: DateFormatter.dateTime(withdrawal.reviewedAt),
                ),
                AdminInfoRow(
                  label: 'Bắt đầu chuyển',
                  value: DateFormatter.dateTime(withdrawal.processingAt),
                ),
                AdminInfoRow(
                  label: 'Ngày thanh toán',
                  value: DateFormatter.dateTime(withdrawal.paidAt),
                ),
                AdminInfoRow(
                  label: 'Ghi chú của quản trị',
                  value: withdrawal.adminNote ?? '—',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Only the actions the backend accepts for this status are rendered.
class _WithdrawalActionButtons extends ConsumerWidget {
  const _WithdrawalActionButtons({
    required this.withdrawal,
    required this.onApprove,
    required this.onReject,
    required this.onMarkPaid,
    required this.onRetry,
    required this.onRefreshPayout,
  });

  final WithdrawalRequest withdrawal;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onMarkPaid;
  final VoidCallback onRetry;
  final VoidCallback onRefreshPayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = withdrawal.id;
    final busyKeys = ref.watch(adminMutationControllerProvider);
    bool busy(String action) => busyKeys.contains(adminMutationKey(action, id));
    final anyBusy = busyKeys.any((key) => key.endsWith(':$id'));

    final canApprove = WithdrawalActions.canApprove(withdrawal);
    final canReject = WithdrawalActions.canReject(withdrawal);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A pending request is the only one that can still be approved; an
        // approved one keeps only its reject escape hatch.
        if (canApprove && canReject)
          ModerationActionBar(
            approveKey: adminMutationKey('approve-withdrawal', id),
            rejectKey: adminMutationKey('reject-withdrawal', id),
            approveLabel: 'Phê duyệt',
            rejectLabel: 'Từ chối',
            onApprove: onApprove,
            onReject: onReject,
          )
        else if (canReject)
          AppButton(
            label: 'Từ chối',
            icon: Icons.close_rounded,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            loading: busy('reject-withdrawal'),
            onPressed: anyBusy ? null : onReject,
          ),

        if (WithdrawalActions.canMarkPaid(withdrawal)) ...[
          if (canReject) const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Đánh dấu đã thanh toán',
            icon: Icons.task_alt_rounded,
            size: AppButtonSize.medium,
            loading: busy('mark-paid-withdrawal'),
            onPressed: anyBusy ? null : onMarkPaid,
          ),
        ],

        if (WithdrawalActions.canRetryPayout(withdrawal)) ...[
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Thử thanh toán lại',
            icon: Icons.replay_rounded,
            size: AppButtonSize.medium,
            loading: busy('retry-payout'),
            onPressed: anyBusy ? null : onRetry,
          ),
        ],

        if (WithdrawalActions.canRefreshPayoutStatus(withdrawal)) ...[
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Cập nhật trạng thái thanh toán',
            icon: Icons.sync_rounded,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.medium,
            loading: busy('refresh-payout'),
            onPressed: anyBusy ? null : onRefreshPayout,
          ),
        ],
      ],
    );
  }
}
