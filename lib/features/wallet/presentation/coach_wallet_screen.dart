import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../data/models/coach_wallet.dart';
import 'wallet_controller.dart';

/// Coach wallet: balances + ledger. Withdrawals are view-only in phase 1 —
/// the button leads to a "coming soon" explanation.
class CoachWalletScreen extends ConsumerStatefulWidget {
  const CoachWalletScreen({super.key});

  @override
  ConsumerState<CoachWalletScreen> createState() => _CoachWalletScreenState();
}

class _CoachWalletScreenState extends ConsumerState<CoachWalletScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        ref.read(walletTransactionsControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(coachWalletProvider);
    final transactions = ref.watch(walletTransactionsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ví của tôi')),
      body: SafeArea(
        child: switch (wallet) {
          AsyncData(value: final walletData) => RefreshIndicator(
            onRefresh: () => ref
                .read(walletTransactionsControllerProvider.notifier)
                .refresh(),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xs,
                AppSpacing.screenH,
                AppSpacing.xl,
              ),
              children: [
                _BalanceCard(wallet: walletData),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Tổng thu nhập',
                        value: CurrencyFormatter.vnd(walletData.totalEarned),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        background: AppColors.successSoft,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _StatCard(
                        label: 'Đã rút',
                        value: CurrencyFormatter.vnd(walletData.totalWithdrawn),
                        icon: Icons.output_rounded,
                        color: AppColors.info,
                        background: AppColors.infoSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Rút tiền',
                  icon: Icons.account_balance_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      context.push(RouteNames.withdrawalComingSoon),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Tính năng rút tiền sẽ được hỗ trợ sau.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Lịch sử giao dịch', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                switch (transactions) {
                  AsyncData(:final value) =>
                    value.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.lg),
                            child: AppEmptyState(
                              icon: Icons.receipt_rounded,
                              title: 'Chưa có giao dịch',
                              message:
                                  'Thu nhập từ các buổi tập hoàn thành sẽ '
                                  'hiển thị tại đây.',
                            ),
                          )
                        : Column(
                            children: [
                              for (final transaction in value.items) ...[
                                _TransactionTile(transaction: transaction),
                                const SizedBox(height: AppSpacing.xs),
                              ],
                              if (value.hasNext)
                                const Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
                  AsyncError(:final error) => AppErrorState(
                    error: error is ApiError ? error : null,
                    onRetry: () => ref
                        .read(walletTransactionsControllerProvider.notifier)
                        .refresh(),
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                },
              ],
            ),
          ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () => ref.invalidate(coachWalletProvider),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});

  final CoachWallet wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư khả dụng',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            CurrencyFormatter.vnd(wallet.availableBalance),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 14,
                color: AppColors.accentOrange,
              ),
              const SizedBox(width: 4),
              Text(
                'Đang chờ xử lý: ${CurrencyFormatter.vnd(wallet.pendingBalance)}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCredit ? AppColors.successSoft : AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: isCredit ? AppColors.success : AppColors.danger,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.typeLabel, style: AppTextStyles.cardTitle),
                Text(
                  transaction.note ??
                      DateFormatter.dateTime(transaction.createdAt),
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '−'}${CurrencyFormatter.vnd(transaction.amount)}',
            style: AppTextStyles.cardTitle.copyWith(
              color: isCredit ? AppColors.success : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
