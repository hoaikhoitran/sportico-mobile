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
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../sessions/presentation/session_actions.dart';
import '../../sessions/presentation/widgets/session_tile.dart';
import '../data/models/booking.dart';
import 'bookings_controller.dart';

/// Booking detail shared by learner and coach. The coach variant reads
/// `/bookings/coach/{id}` and unlocks session confirm/complete actions plus
/// the earnings breakdown.
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.asCoach,
  });

  final String bookingId;
  final bool asCoach;

  BookingDetailArgs get _args => (id: bookingId, asCoach: asCoach);

  void _refresh(WidgetRef ref) {
    ref.invalidate(bookingDetailProvider(_args));
    ref.invalidate(bookingSessionsProvider(bookingId));
    // Session transitions change booking progress and (for coaches) wallet.
    ref.invalidate(bookingsControllerProvider(asCoach));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(bookingDetailProvider(_args));
    final sessions = ref.watch(bookingSessionsProvider(bookingId));
    final actions = SessionActions(ref);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn đăng ký')),
      body: SafeArea(
        child: switch (detail) {
          AsyncData(value: final booking) => RefreshIndicator(
            onRefresh: () async => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xs,
                AppSpacing.screenH,
                AppSpacing.xl,
              ),
              children: [
                _SummaryCard(booking: booking),
                const SizedBox(height: AppSpacing.md),
                _MoneyCard(booking: booking, asCoach: asCoach),
                const SizedBox(height: AppSpacing.md),
                _PersonalizedLinks(bookingId: bookingId),
                const SizedBox(height: AppSpacing.lg),
                Text('Các buổi tập', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                switch (sessions) {
                  AsyncData(:final value) =>
                    value.isEmpty
                        ? Text(
                            'Chưa có buổi tập nào.',
                            style: AppTextStyles.bodySecondary,
                          )
                        : Column(
                            children: [
                              for (final (i, session) in value.indexed) ...[
                                SessionTile(
                                  session: session,
                                  index: i + 1,
                                  isCoach: asCoach,
                                  onConfirm: () async {
                                    if (await actions.confirm(
                                      context,
                                      session,
                                    )) {
                                      _refresh(ref);
                                    }
                                  },
                                  onCancel: () async {
                                    if (await actions.cancel(
                                      context,
                                      session,
                                    )) {
                                      _refresh(ref);
                                    }
                                  },
                                  onComplete: () async {
                                    if (await actions.complete(
                                      context,
                                      session,
                                    )) {
                                      _refresh(ref);
                                    }
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xs),
                              ],
                            ],
                          ),
                  AsyncError(:final error) => AppErrorState(
                    error: error is ApiError ? error : null,
                    onRetry: () =>
                        ref.invalidate(bookingSessionsProvider(bookingId)),
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
            onRetry: () => _refresh(ref),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking});

  final Booking booking;

  AppBadgeTone get _tone => switch (booking.status) {
    BookingStatus.active => AppBadgeTone.info,
    BookingStatus.completed => AppBadgeTone.success,
    BookingStatus.pendingPayment => AppBadgeTone.warning,
    BookingStatus.cancelled || BookingStatus.refunded => AppBadgeTone.danger,
    BookingStatus.unknown => AppBadgeTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.trainingPackageTitle,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppBadge(label: booking.status.label, tone: _tone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: booking.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDE7D8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Hoàn thành ${booking.completedSessions}/${booking.totalSessions} buổi',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Ngày thanh toán',
            value: DateFormatter.dateTime(booking.paidAt),
          ),
          if (booking.expiresAt != null)
            _DetailRow(
              label: 'Hết hạn đặt lịch',
              value: DateFormatter.date(booking.expiresAt),
            ),
          if (booking.completedAt != null)
            _DetailRow(
              label: 'Hoàn thành lúc',
              value: DateFormatter.dateTime(booking.completedAt),
            ),
          if (booking.cancelledAt != null)
            _DetailRow(
              label: 'Hủy lúc',
              value: DateFormatter.dateTime(booking.cancelledAt),
            ),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.booking, required this.asCoach});

  final Booking booking;
  final bool asCoach;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asCoach ? 'Thu nhập từ đơn này' : 'Thanh toán',
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Giá gói',
            value: booking.totalAmountLabel,
            emphasize: !asCoach,
          ),
          if (asCoach) ...[
            _DetailRow(
              label:
                  'Phí nền tảng '
                  '(${(booking.platformFeeRate * 100).toStringAsFixed(0)}%)',
              value: '- ${CurrencyFormatter.vnd(booking.platformFeeAmount)}',
            ),
            _DetailRow(
              label: 'Bạn nhận (tổng)',
              value: CurrencyFormatter.vnd(booking.coachReceiveAmount),
              emphasize: true,
            ),
            _DetailRow(
              label: 'Mỗi buổi hoàn thành',
              value: CurrencyFormatter.vnd(booking.perSessionCoachAmount),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Thu nhập được cộng vào ví sau mỗi buổi tập hoàn thành.',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _PersonalizedLinks extends StatelessWidget {
  const _PersonalizedLinks({required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            title: Text('Đánh giá đầu vào', style: AppTextStyles.cardTitle),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
            onTap: () => context.push(RouteNames.assessmentPath(bookingId)),
          ),
          const Divider(indent: 52),
          ListTile(
            leading: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            title: Text('Giáo án luyện tập', style: AppTextStyles.cardTitle),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
            onTap: () => context.push(RouteNames.trainingPlanPath(bookingId)),
          ),
          const Divider(indent: 52),
          ListTile(
            leading: const Icon(
              Icons.monitor_weight_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            title: Text('Ghi nhận tiến độ', style: AppTextStyles.cardTitle),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
            onTap: () =>
                context.push(RouteNames.progressCheckInsPath(bookingId)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(
            value,
            style: emphasize
                ? AppTextStyles.price
                : AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
