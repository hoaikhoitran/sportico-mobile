import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../notifications/presentation/notifications_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final name = auth.user?.fullName ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.lg,
            AppSpacing.screenH,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Xin chào!' : 'Xin chào, $name!',
                        style: AppTextStyles.screenTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hôm nay bạn muốn luyện tập gì?',
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),
                _NotificationBell(
                  onTap: () => context.push(RouteNames.notifications),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _HeroBanner(onExplore: () => context.go(RouteNames.packages)),
            const SizedBox(height: AppSpacing.xl),
            Text('Truy cập nhanh', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            // Rows of equally stretched cards: the height follows the
            // content, so large system fonts or narrow screens never clip.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.fitness_center_rounded,
                      color: AppColors.accentOrange,
                      background: AppColors.accentOrangeSoft,
                      title: 'Gói tập',
                      subtitle: 'Khám phá gói luyện tập',
                      onTap: () => context.go(RouteNames.packages),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.info,
                      background: AppColors.infoSoft,
                      title: 'Lịch tập',
                      subtitle: 'Buổi tập sắp tới',
                      onTap: () => context.go(RouteNames.schedule),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.success,
                      background: AppColors.successSoft,
                      title: 'Đơn đăng ký',
                      subtitle: 'Gói tập đã mua',
                      onTap: () => context.push(RouteNames.bookings),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.chat_bubble_rounded,
                      color: AppColors.primary,
                      background: AppColors.accentBlueSoft,
                      title: 'Tin nhắn',
                      subtitle: 'Trao đổi với HLV',
                      onTap: () => context.go(RouteNames.messages),
                    ),
                  ),
                ],
              ),
            ),
            if (auth.isCoach) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Khu vực huấn luyện viên',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              _CoachShortcuts(),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Badge.count(
      count: unread,
      isLabelVisible: unread > 0,
      backgroundColor: AppColors.accentOrange,
      offset: const Offset(-4, 4),
      child: IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.notifications_outlined),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onExplore});

  final VoidCallback onExplore;

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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tìm huấn luyện viên phù hợp',
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Gói tập được thiết kế theo lịch cố định, minh bạch và rõ ràng.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: onExplore,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    textStyle: AppTextStyles.button.copyWith(fontSize: 13.5),
                  ),
                  child: const Text('Khám phá ngay'),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.sports_gymnastics_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.cardTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CoachShortcuts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _CoachTile(
            icon: Icons.inventory_2_outlined,
            title: 'Gói tập của tôi',
            onTap: () => context.push(RouteNames.coachPackages),
          ),
          const Divider(indent: AppSpacing.md + 36),
          _CoachTile(
            icon: Icons.assignment_outlined,
            title: 'Học viên đăng ký',
            onTap: () => context.push(RouteNames.coachBookings),
          ),
          const Divider(indent: AppSpacing.md + 36),
          _CoachTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Ví của tôi',
            onTap: () => context.push(RouteNames.coachWallet),
          ),
        ],
      ),
    );
  }
}

class _CoachTile extends StatelessWidget {
  const _CoachTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTextStyles.cardTitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
