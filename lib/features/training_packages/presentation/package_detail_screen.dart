import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../bookings/data/booking_repository.dart';
import '../data/models/training_package.dart';
import 'package_list_controller.dart';

/// Public package detail: info, coach, fixed schedule, PayOS purchase CTA.
class PackageDetailScreen extends ConsumerStatefulWidget {
  const PackageDetailScreen({super.key, required this.packageId});

  final String packageId;

  @override
  ConsumerState<PackageDetailScreen> createState() =>
      _PackageDetailScreenState();
}

class _PackageDetailScreenState extends ConsumerState<PackageDetailScreen> {
  bool _purchasing = false;

  Future<void> _purchase(TrainingPackage package) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => _PurchaseSheet(package: package),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _purchasing = true);
    final result = await ref
        .read(bookingRepositoryProvider)
        .purchasePayOs(package.id);
    if (!mounted) return;
    setState(() => _purchasing = false);

    switch (result) {
      case ApiSuccess(data: final purchase):
        final checkoutUrl = purchase.checkoutUrl;
        if (checkoutUrl != null) {
          await launchUrl(
            Uri.parse(checkoutUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        if (!mounted) return;
        AppSnackBar.success(
          context,
          'Đã tạo đơn — hoàn tất thanh toán trong trang PayOS vừa mở.',
        );
        ref.invalidate(packageDetailProvider(widget.packageId));
        context.push(RouteNames.bookingDetailPath(purchase.bookingId));
      case ApiFailure(:final error):
        AppSnackBar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(packageDetailProvider(widget.packageId));
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết gói tập')),
      body: SafeArea(
        child: switch (detail) {
          AsyncData(value: final package) => _Body(
            package: package,
            auth: auth,
            purchasing: _purchasing,
            onPurchase: () => _purchase(package),
          ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () =>
                ref.invalidate(packageDetailProvider(widget.packageId)),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.package,
    required this.auth,
    required this.purchasing,
    required this.onPurchase,
  });

  final TrainingPackage package;
  final AuthState auth;
  final bool purchasing;
  final VoidCallback onPurchase;

  bool get _isOwnPackage =>
      auth.user != null && auth.user!.id == package.coachId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.screenH,
              AppSpacing.xl,
            ),
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  AppBadge(label: package.sportName, tone: AppBadgeTone.brand),
                  AppBadge(
                    label: package.isOnline ? 'Online' : 'Trực tiếp',
                    tone: package.isOnline
                        ? AppBadgeTone.info
                        : AppBadgeTone.success,
                  ),
                  AppBadge(
                    label: PackageLabels.level(package.level),
                    tone: AppBadgeTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(package.title, style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                package.priceLabel,
                style: AppTextStyles.price.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoGrid(package: package),
              if (package.coach != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Huấn luyện viên', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                _CoachCard(
                  coach: package.coach!,
                  onTap: () =>
                      context.push(RouteNames.coachDetailPath(package.coachId)),
                ),
              ],
              if (package.description?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Mô tả', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(package.description!, style: AppTextStyles.body),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text('Lịch tập cố định', style: AppTextStyles.sectionTitle),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${package.sessions.length} buổi',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final slot in package.sessions) ...[
                _SlotTile(slot: slot),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (package.sessions.isEmpty)
                Text(
                  'Gói tập chưa công bố lịch chi tiết.',
                  style: AppTextStyles.bodySecondary,
                ),
            ],
          ),
        ),
        _BottomBar(
          package: package,
          auth: auth,
          isOwnPackage: _isOwnPackage,
          purchasing: purchasing,
          onPurchase: onPurchase,
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.package});

  final TrainingPackage package;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.event_repeat_rounded,
            label: 'Số buổi tập',
            value: '${package.sessionCount} buổi',
          ),
          const Divider(height: AppSpacing.lg),
          _InfoRow(
            icon: Icons.date_range_rounded,
            label: 'Thời gian',
            value:
                '${DateFormatter.date(package.startDate)} → ${DateFormatter.date(package.endDate)}',
          ),
          const Divider(height: AppSpacing.lg),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: 'Mục tiêu',
            value: PackageLabels.goal(package.goalType),
          ),
          const Divider(height: AppSpacing.lg),
          _InfoRow(
            icon: package.isOnline
                ? Icons.videocam_outlined
                : Icons.place_outlined,
            label: 'Hình thức',
            value: package.isOnline
                ? 'Tập online'
                : (package.location ?? 'Trực tiếp'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.accentBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach, this.onTap});

  final PackageCoachSummary coach;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.accentBlueSoft,
            foregroundImage: coach.avatarUrl != null
                ? CachedNetworkImageProvider(coach.avatarUrl!)
                : null,
            child: Text(
              coach.fullName.isNotEmpty ? coach.fullName[0].toUpperCase() : '?',
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.fullName,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (coach.headline != null)
                  Text(
                    coach.headline!,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    if (coach.totalReviews > 0) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${coach.rating.toStringAsFixed(1)} (${coach.totalReviews})',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (coach.experienceYears != null)
                      Text(
                        '${coach.experienceYears} năm kinh nghiệm',
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot});

  final PackageSessionSlot slot;

  @override
  Widget build(BuildContext context) {
    final remaining = slot.remainingParticipants;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentBlueSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '${slot.sessionNumber}',
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.weekdayDate(slot.startTime),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${DateFormatter.timeRange(slot.startTime, slot.endTime)}'
                  '${slot.isOnline ? ' · Online' : (slot.location != null ? ' · ${slot.location}' : '')}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (slot.status == SlotStatus.cancelled)
            const AppBadge(label: 'Đã hủy', tone: AppBadgeTone.danger)
          else if (slot.status == SlotStatus.full)
            const AppBadge(label: 'Hết chỗ', tone: AppBadgeTone.warning)
          else if (remaining != null)
            AppBadge(label: 'Còn $remaining chỗ', tone: AppBadgeTone.success),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.package,
    required this.auth,
    required this.isOwnPackage,
    required this.purchasing,
    required this.onPurchase,
  });

  final TrainingPackage package;
  final AuthState auth;
  final bool isOwnPackage;
  final bool purchasing;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final Widget content;

    if (isOwnPackage) {
      content = Text(
        'Đây là gói tập của bạn.',
        style: AppTextStyles.bodySecondary,
        textAlign: TextAlign.center,
      );
    } else if (!auth.isAuthenticated) {
      content = AppButton(
        label: 'Đăng nhập để đăng ký',
        onPressed: () => context.go(RouteNames.login),
      );
    } else if (!auth.isLearner) {
      content = Text(
        'Chỉ tài khoản người tập mới có thể đăng ký gói tập.',
        style: AppTextStyles.bodySecondary,
        textAlign: TextAlign.center,
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'Đăng ký gói tập — ${package.priceLabel}',
            onPressed: onPurchase,
            loading: purchasing,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Thanh toán an toàn qua PayOS.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: content,
    );
  }
}

/// Manual-purchase confirmation sheet.
class _PurchaseSheet extends StatelessWidget {
  const _PurchaseSheet({required this.package});

  final TrainingPackage package;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Xác nhận đăng ký', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(package.title, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng thanh toán', style: AppTextStyles.bodySecondary),
                Text(package.priceLabel, style: AppTextStyles.price),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.infoSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                'Bạn sẽ được chuyển sang trang thanh toán PayOS. Sau khi '
                'thanh toán thành công, lịch tập được tạo tự động theo lịch '
                'của gói.',
                style: AppTextStyles.caption.copyWith(color: AppColors.info),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Tiếp tục thanh toán',
              icon: Icons.open_in_new_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Để sau',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
