import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../chat/data/chat_api.dart';
import '../../chat/presentation/chat_controller.dart';
import '../data/coach_directory_api.dart';
import '../data/models/public_coach.dart';
import 'coach_directory_providers.dart';

/// Public coach profile: bio, sports, published packages, reviews, and a
/// shortcut to start chatting with the coach.
class CoachDetailScreen extends ConsumerStatefulWidget {
  const CoachDetailScreen({super.key, required this.coachId});

  final String coachId;

  @override
  ConsumerState<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends ConsumerState<CoachDetailScreen> {
  bool _openingChat = false;

  Future<void> _openChat(PublicCoachDetail coach) async {
    if (_openingChat) return;
    setState(() => _openingChat = true);
    final result = await ref.read(chatApiProvider).createRoom(coach.coachId);
    if (!mounted) return;
    setState(() => _openingChat = false);

    switch (result) {
      case ApiSuccess(data: final room):
        ref.invalidate(chatRoomsProvider);
        context.push(RouteNames.chatDetailPath(room.id), extra: coach.fullName);
      case ApiFailure(:final error):
        AppSnackBar.error(context, error.userMessage);
    }
  }

  Future<void> _writeReview(PublicCoachDetail coach) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ReviewSheet(coachId: coach.coachId),
    );
    if (submitted == true) {
      ref.invalidate(coachReviewsProvider(widget.coachId));
      ref.invalidate(coachReviewSummaryProvider(widget.coachId));
      ref.invalidate(coachDetailProvider(widget.coachId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(coachDetailProvider(widget.coachId));
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ huấn luyện viên')),
      body: SafeArea(
        child: switch (detail) {
          AsyncData(value: final coach) => _Body(
            coach: coach,
            auth: auth,
            openingChat: _openingChat,
            onOpenChat: () => _openChat(coach),
            onWriteReview: () => _writeReview(coach),
          ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () => ref.invalidate(coachDetailProvider(widget.coachId)),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.coach,
    required this.auth,
    required this.openingChat,
    required this.onOpenChat,
    required this.onWriteReview,
  });

  final PublicCoachDetail coach;
  final AuthState auth;
  final bool openingChat;
  final VoidCallback onOpenChat;
  final VoidCallback onWriteReview;

  bool get _isSelf => auth.user != null && auth.user!.id == coach.coachId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(coachReviewSummaryProvider(coach.coachId)).value;
    final reviews = ref.watch(coachReviewsProvider(coach.coachId)).value;
    final publishedPackages = coach.trainingPackages
        .where((p) => p.status == 'published')
        .toList();

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
              _Header(coach: coach),
              if (coach.bio?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Giới thiệu', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(coach.bio!, style: AppTextStyles.body),
              ],
              if (coach.specialties?.isNotEmpty == true ||
                  coach.achievementsSummary?.isNotEmpty == true ||
                  coach.teachingAddress?.isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: Column(
                    children: [
                      if (coach.specialties?.isNotEmpty == true)
                        _InfoRow(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Chuyên môn',
                          value: coach.specialties!,
                        ),
                      if (coach.achievementsSummary?.isNotEmpty == true)
                        _InfoRow(
                          icon: Icons.emoji_events_outlined,
                          label: 'Thành tích',
                          value: coach.achievementsSummary!,
                        ),
                      if (coach.teachingAddress?.isNotEmpty == true)
                        _InfoRow(
                          icon: Icons.place_outlined,
                          label: 'Địa điểm dạy',
                          value: coach.teachingAddress!,
                        ),
                    ],
                  ),
                ),
              ],
              if (publishedPackages.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Gói tập đang mở bán', style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                for (final package in publishedPackages) ...[
                  _PackageTile(
                    package: package,
                    onTap: () =>
                        context.push(RouteNames.packageDetailPath(package.id)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text('Đánh giá', style: AppTextStyles.sectionTitle),
                  ),
                  if (auth.isAuthenticated && auth.isLearner && !_isSelf)
                    TextButton.icon(
                      onPressed: onWriteReview,
                      icon: const Icon(Icons.rate_review_outlined, size: 18),
                      label: const Text('Viết đánh giá'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (summary != null && summary.totalReviews > 0)
                _SummaryCard(summary: summary),
              if (reviews == null)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (reviews.isEmpty)
                Text(
                  'Chưa có đánh giá nào. Hãy là người đầu tiên đánh giá '
                  'huấn luyện viên này!',
                  style: AppTextStyles.bodySecondary,
                )
              else ...[
                const SizedBox(height: AppSpacing.xs),
                for (final review in reviews.items) ...[
                  _ReviewTile(review: review),
                  const SizedBox(height: AppSpacing.xs),
                ],
                if (reviews.hasNext)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Hiển thị ${reviews.items.length}/${reviews.totalCount} '
                      'đánh giá gần nhất.',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (auth.isAuthenticated && !_isSelf)
          Container(
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
            child: AppButton(
              label: 'Nhắn tin với HLV',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: onOpenChat,
              loading: openingChat,
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.coach});

  final PublicCoachDetail coach;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.accentBlueSoft,
                foregroundImage: coach.avatarUrl != null
                    ? CachedNetworkImageProvider(coach.avatarUrl!)
                    : null,
                child: Text(
                  coach.fullName.isNotEmpty
                      ? coach.fullName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.screenTitle.copyWith(
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
                      style: AppTextStyles.sectionTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (coach.headline?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        coach.headline!,
                        style: AppTextStyles.bodySecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final sport in coach.sports)
                AppBadge(label: sport.name, tone: AppBadgeTone.brand),
              if (coach.isOnlineAvailable)
                const AppBadge(label: 'Dạy online', tone: AppBadgeTone.info),
              if (coach.isOfflineAvailable)
                const AppBadge(
                  label: 'Dạy trực tiếp',
                  tone: AppBadgeTone.success,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (coach.totalReviews > 0) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 2),
                Text(
                  '${coach.rating.toStringAsFixed(1)} '
                  '(${coach.totalReviews} đánh giá)',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (coach.experienceYears != null) ...[
                Text(
                  '${coach.experienceYears} năm kinh nghiệm',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (coach.locationLabel != null)
                Expanded(
                  child: Text(
                    coach.locationLabel!,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.accentBlue),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 96,
            child: Text(label, style: AppTextStyles.bodySecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package, required this.onTap});

  final CoachPackageItem package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.title,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${package.sportName} · ${package.sessionCount} buổi'
                  '${package.isOnline ? ' · Online' : ''}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(package.priceLabel, style: AppTextStyles.price),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final CoachReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: AppTextStyles.displayTitle,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= summary.averageRating.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 15,
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${summary.totalReviews} đánh giá',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Row(
                      children: [
                        Text('$star', style: AppTextStyles.caption),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusPill,
                            ),
                            child: LinearProgressIndicator(
                              value: summary.totalReviews == 0
                                  ? 0
                                  : summary.breakdown[star - 1] /
                                        summary.totalReviews,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceMuted,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final CoachReview review;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.accentBlueSoft,
                foregroundImage: review.learnerAvatarUrl != null
                    ? CachedNetworkImageProvider(review.learnerAvatarUrl!)
                    : null,
                child: Text(
                  review.learnerName.isNotEmpty
                      ? review.learnerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  review.learnerName,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 14,
                  color: AppColors.warning,
                ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment!, style: AppTextStyles.body),
          ],
          if (review.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              DateFormatter.date(review.createdAt!),
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

/// Star picker + comment for a new review.
class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.coachId});

  final String coachId;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final result = await ref
        .read(coachDirectoryApiProvider)
        .createReview(
          widget.coachId,
          rating: _rating,
          comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
        );
    if (!mounted) return;

    switch (result) {
      case ApiSuccess():
        AppSnackBar.success(context, 'Cảm ơn bạn đã đánh giá!');
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() => _submitting = false);
        AppSnackBar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Đánh giá huấn luyện viên', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  tooltip: '$star sao',
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 32,
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Chia sẻ trải nghiệm của bạn (tùy chọn)…',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Gửi đánh giá',
            onPressed: _submit,
            loading: _submitting,
          ),
        ],
      ),
    );
  }
}
