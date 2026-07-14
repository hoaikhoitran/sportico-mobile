import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../shared/widgets/admin_info_row.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../../shared/widgets/admin_status_chip.dart';
import '../data/models/withdrawal_request.dart';
import 'admin_withdrawals_controller.dart';

/// Payout receipt.
///
/// The backend returns structured receipt data only — there is no PDF/file
/// endpoint — so this is a readable on-screen record with copyable references,
/// not a fake "download". The account number arrives already masked.
class AdminWithdrawalReceiptScreen extends ConsumerWidget {
  const AdminWithdrawalReceiptScreen({super.key, required this.withdrawalId});

  final String withdrawalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminWithdrawalReceiptProvider(withdrawalId));

    return Scaffold(
      appBar: AppBar(title: const Text('Biên nhận')),
      body: SafeArea(
        child: switch (state) {
          AsyncData(:final value) => _ReceiptBody(receipt: value),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () =>
                ref.invalidate(adminWithdrawalReceiptProvider(withdrawalId)),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.receipt});

  final WithdrawalReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                receipt.receiptNumber ?? 'Biên nhận rút tiền',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(receipt.amountLabel, style: AppTextStyles.displayTitle),
              if (receipt.currency != null) ...[
                const SizedBox(height: 2),
                Text(receipt.currency!, style: AppTextStyles.caption),
              ],
              const SizedBox(height: AppSpacing.sm),
              AdminStatusChip(
                label: receipt.status.label,
                tone: receipt.status.tone,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const AdminSectionHeader(title: 'Người nhận'),
        AppCard(
          child: Column(
            children: [
              AdminInfoRow(
                label: 'Huấn luyện viên',
                value: receipt.coachName ?? '—',
                emphasize: true,
              ),
              AdminInfoRow(label: 'Email', value: receipt.coachEmail ?? '—'),
              AdminInfoRow(label: 'Ngân hàng', value: receipt.bankName ?? '—'),
              AdminInfoRow(label: 'Mã BIN', value: receipt.bankBin ?? '—'),
              AdminInfoRow(
                label: 'Số tài khoản',
                value: receipt.maskedAccountNumber ?? '—',
              ),
              AdminInfoRow(
                label: 'Chủ tài khoản',
                value: receipt.accountHolderName ?? '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const AdminSectionHeader(title: 'Giao dịch'),
        AppCard(
          child: Column(
            children: [
              AdminInfoRow(
                label: 'Mã lệnh chi',
                value: receipt.payOsPayoutId ?? '—',
                copyable: true,
              ),
              AdminInfoRow(
                label: 'Mã tham chiếu',
                value: receipt.payOsReferenceId ?? '—',
                copyable: true,
              ),
              AdminInfoRow(
                label: 'Trạng thái PayOS',
                value: receipt.payOsPayoutStatus ?? '—',
              ),
              AdminInfoRow(
                label: 'Ngày yêu cầu',
                value: DateFormatter.dateTime(receipt.createdAt),
              ),
              AdminInfoRow(
                label: 'Bắt đầu chuyển',
                value: DateFormatter.dateTime(receipt.processingAt),
              ),
              AdminInfoRow(
                label: 'Ngày thanh toán',
                value: DateFormatter.dateTime(receipt.paidAt),
              ),
              if (receipt.failureReason != null)
                AdminInfoRow(
                  label: 'Lý do thất bại',
                  value: receipt.failureReason!,
                ),
              if (receipt.adminNote != null)
                AdminInfoRow(
                  label: 'Ghi chú quản trị',
                  value: receipt.adminNote!,
                ),
              if (receipt.note != null)
                AdminInfoRow(label: 'Ghi chú', value: receipt.note!),
            ],
          ),
        ),
      ],
    );
  }
}
