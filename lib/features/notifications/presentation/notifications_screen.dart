import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../data/models/app_notification.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        ref.read(notificationsControllerProvider.notifier).loadMore();
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
    final listState = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final hasUnread = listState.value?.items.any((n) => !n.isRead) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: controller.markAllRead,
              child: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (listState) {
          AsyncData(:final value) =>
            value.isEmpty
                ? const AppEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'Chưa có thông báo',
                    message:
                        'Thông báo về đơn đăng ký, buổi tập và ví sẽ hiển thị '
                        'tại đây.',
                  )
                : RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.xs,
                        AppSpacing.screenH,
                        AppSpacing.xl,
                      ),
                      itemCount: value.items.length + (value.hasNext ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        if (index >= value.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final notification = value.items[index];
                        return _NotificationTile(
                          notification: notification,
                          onTap: () => controller.markRead(notification),
                        );
                      },
                    ),
                  ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: controller.refresh,
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  (IconData, Color, Color) get _visual => switch (notification.type) {
    'booking' => (
      Icons.receipt_long_rounded,
      AppColors.success,
      AppColors.successSoft,
    ),
    'training_session' => (
      Icons.event_available_rounded,
      AppColors.info,
      AppColors.infoSoft,
    ),
    'wallet' || 'payment' => (
      Icons.account_balance_wallet_rounded,
      AppColors.accentOrange,
      AppColors.accentOrangeSoft,
    ),
    'training_package' || 'package' => (
      Icons.fitness_center_rounded,
      AppColors.primary,
      AppColors.accentBlueSoft,
    ),
    'training_plan' => (
      Icons.menu_book_rounded,
      AppColors.primary,
      AppColors.accentBlueSoft,
    ),
    'message' => (
      Icons.chat_bubble_rounded,
      AppColors.info,
      AppColors.infoSoft,
    ),
    'review' => (Icons.star_rounded, AppColors.warning, AppColors.warningSoft),
    _ => (
      Icons.notifications_rounded,
      AppColors.textSecondary,
      AppColors.surfaceMuted,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = _visual;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: notification.isRead
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
                if (notification.content?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    notification.content!,
                    style: AppTextStyles.bodySecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  DateFormatter.dateTime(notification.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 6, left: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.accentOrange,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
