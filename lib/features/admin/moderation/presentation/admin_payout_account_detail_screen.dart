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
import '../data/models/coach_payout_account.dart';
import 'payout_accounts_controller.dart';
import 'widgets/moderation_action_bar.dart';

/// Payout account under verification.
///
/// This is the only surface that shows the full account number — the admin
/// needs it to match the account against the coach's identity. It is never
/// logged, and the list only ever shows the masked form.
class AdminPayoutAccountDetailScreen extends ConsumerWidget {
  const AdminPayoutAccountDetailScreen({
    super.key,
    required this.accountId,
    this.initial,
  });

  final String accountId;
  final CoachPayoutAccount? initial;

  Future<void> _verify(
    BuildContext context,
    WidgetRef ref,
    CoachPayoutAccount account,
  ) async {
    final confirmed = await showAdminConfirmation(
      context,
      title: 'Xác minh tài khoản',
      message:
          'Sau khi xác minh, hệ thống có thể chi trả tiền rút về tài khoản '
          '${account.maskedAccountNumber}. Bạn có chắc chắn?',
      confirmLabel: 'Xác minh',
    );
    if (!confirmed || !context.mounted) return;

    final error = await ref
        .read(payoutAccountsControllerProvider.notifier)
        .verify(account.id);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    AppSnackBar.success(context, 'Đã xác minh tài khoản nhận tiền.');
    Navigator.of(context).pop();
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    CoachPayoutAccount account,
  ) async {
    final note = await showAdminRejectReasonSheet(
      context,
      title: 'Từ chối tài khoản',
      description: 'Ghi chú giúp huấn luyện viên cập nhật lại thông tin.',
      label: 'Ghi chú',
      submitLabel: 'Từ chối',
      reasonRequired: false,
    );
    if (note == null || !context.mounted) return;

    final error = await ref
        .read(payoutAccountsControllerProvider.notifier)
        .reject(account.id, note);
    if (!context.mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    AppSnackBar.success(context, 'Đã từ chối tài khoản nhận tiền.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(payoutAccountsControllerProvider);
    final account =
        ref
            .read(payoutAccountsControllerProvider.notifier)
            .findById(accountId) ??
        initial;

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tài khoản nhận tiền')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'Tài khoản không còn trong hàng chờ xác minh.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh tài khoản')),
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
              children: [
                Expanded(
                  child: Text(
                    account.bankName ?? 'Ngân hàng chưa xác định',
                    style: AppTextStyles.screenTitle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AdminStatusChip(
                  label: account.status.label,
                  tone: account.status.tone,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppCard(
              child: AdminIdentityLine(
                userId: account.coachId,
                prefix: 'HLV',
                showEmail: true,
                avatarSize: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const AdminSectionHeader(
              title: 'Thông tin nhận tiền',
              subtitle:
                  'Đối chiếu với hồ sơ huấn luyện viên trước khi xác minh',
            ),
            AppCard(
              child: Column(
                children: [
                  AdminInfoRow(
                    label: 'Hình thức',
                    value: account.payoutMethod ?? '—',
                  ),
                  AdminInfoRow(
                    label: 'Ngân hàng',
                    value: account.bankName ?? '—',
                  ),
                  AdminInfoRow(label: 'Mã BIN', value: account.bankBin ?? '—'),
                  AdminInfoRow(
                    label: 'Số tài khoản',
                    value: account.bankAccountNumber ?? '—',
                    emphasize: true,
                    copyable: true,
                  ),
                  AdminInfoRow(
                    label: 'Chủ tài khoản',
                    value: account.bankAccountHolder ?? '—',
                    emphasize: true,
                  ),
                  AdminInfoRow(
                    label: 'Ngày gửi',
                    value: DateFormatter.dateTime(account.createdAt),
                  ),
                  AdminInfoRow(
                    label: 'Cập nhật',
                    value: DateFormatter.dateTime(account.updatedAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Thông tin tài khoản là dữ liệu nhạy cảm. Chỉ dùng để đối '
                      'chiếu khi xác minh.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.onWarningContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: account.status.isPending
          ? AdminBottomActionBar(
              child: ModerationActionBar(
                approveLabel: 'Xác minh',
                approveKey: adminMutationKey(
                  'verify-payout-account',
                  account.id,
                ),
                rejectKey: adminMutationKey(
                  'reject-payout-account',
                  account.id,
                ),
                onApprove: () => _verify(context, ref, account),
                onReject: () => _reject(context, ref, account),
              ),
            )
          : null,
    );
  }
}
