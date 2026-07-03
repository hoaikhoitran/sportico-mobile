import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../data/models/booking.dart';
import '../bookings_controller.dart';

/// Filter chips + paginated booking list, shared by learner and coach views.
class BookingListBody extends ConsumerStatefulWidget {
  const BookingListBody({
    super.key,
    required this.asCoach,
    required this.onOpen,
  });

  final bool asCoach;
  final void Function(Booking booking) onOpen;

  @override
  ConsumerState<BookingListBody> createState() => _BookingListBodyState();
}

class _BookingListBodyState extends ConsumerState<BookingListBody> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        ref
            .read(bookingsControllerProvider(widget.asCoach).notifier)
            .loadMore();
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
    final provider = bookingsControllerProvider(widget.asCoach);
    final listState = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Column(
      children: [
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: AppSpacing.xs,
            ),
            children: [
              for (final (label, status) in [
                ('Tất cả', null),
                ('Đang hoạt động', BookingStatus.active),
                ('Hoàn thành', BookingStatus.completed),
                ('Đã hủy', BookingStatus.cancelled),
              ]) ...[
                ChoiceChip(
                  label: Text(label),
                  selected: controller.statusFilter == status,
                  onSelected: (_) => controller.setFilter(status),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        Expanded(
          child: switch (listState) {
            AsyncData(:final value) =>
              value.isEmpty
                  ? AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: widget.asCoach
                          ? 'Chưa có học viên đăng ký'
                          : 'Bạn chưa đăng ký gói tập nào',
                      message: widget.asCoach
                          ? 'Khi học viên mua gói tập của bạn, đơn sẽ xuất hiện '
                                'tại đây.'
                          : 'Khám phá các gói tập và bắt đầu hành trình luyện '
                                'tập của bạn.',
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
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          if (index >= value.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final booking = value.items[index];
                          return _BookingCard(
                            booking: booking,
                            asCoach: widget.asCoach,
                            onTap: () => widget.onOpen(booking),
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
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.asCoach,
    required this.onTap,
  });

  final Booking booking;
  final bool asCoach;
  final VoidCallback onTap;

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
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  booking.trainingPackageTitle,
                  style: AppTextStyles.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppBadge(label: booking.status.label, tone: _tone),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: booking.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDE7D8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${booking.completedSessions}/${booking.totalSessions} buổi hoàn thành',
                style: AppTextStyles.caption,
              ),
              Text(booking.totalAmountLabel, style: AppTextStyles.price),
            ],
          ),
        ],
      ),
    );
  }
}
