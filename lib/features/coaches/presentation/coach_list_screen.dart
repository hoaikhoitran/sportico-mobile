import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../data/models/public_coach.dart';
import 'coach_directory_providers.dart';

/// Public coach directory (works signed-out too).
class CoachListScreen extends ConsumerStatefulWidget {
  const CoachListScreen({super.key});

  @override
  ConsumerState<CoachListScreen> createState() => _CoachListScreenState();
}

class _CoachListScreenState extends ConsumerState<CoachListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        ref.read(coachListControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(coachListControllerProvider.notifier).search(value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    ref.read(coachListControllerProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(coachListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Huấn luyện viên'),
        actions: [
          IconButton(
            tooltip: 'Gói tập',
            icon: const Icon(Icons.fitness_center_rounded),
            onPressed: () => context.push(RouteNames.packages),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.xs,
                AppSpacing.screenH,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm huấn luyện viên…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: switch (listState) {
                AsyncData(:final value) =>
                  value.isEmpty
                      ? (_searchController.text.isNotEmpty
                            ? AppEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'Không tìm thấy huấn luyện viên',
                                message:
                                    'Không có huấn luyện viên nào khớp với '
                                    'từ khóa.',
                                actionLabel: 'Xóa tìm kiếm',
                                onAction: _clearSearch,
                              )
                            : const AppEmptyState(
                                icon: Icons.sports_rounded,
                                title: 'Chưa có huấn luyện viên',
                                message:
                                    'Danh sách huấn luyện viên sẽ hiển thị '
                                    'tại đây.',
                              ))
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(coachListControllerProvider.notifier)
                              .refresh(),
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.screenH,
                                  AppSpacing.xxs,
                                  AppSpacing.screenH,
                                  AppSpacing.sm,
                                ),
                                sliver: SliverGrid.builder(
                                  gridDelegate: _coachGridDelegate(context),
                                  itemCount: value.items.length,
                                  itemBuilder: (context, index) {
                                    final coach = value.items[index];
                                    return _CoachCard(
                                      coach: coach,
                                      onTap: () => context.push(
                                        RouteNames.coachDetailPath(
                                          coach.coachId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.xl,
                                  ),
                                  child: value.hasNext
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                        ),
                AsyncError(:final error) => AppErrorState(
                  error: error is ApiError ? error : null,
                  onRetry: () =>
                      ref.read(coachListControllerProvider.notifier).refresh(),
                ),
                _ => const _CoachGridSkeleton(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Two cards per row. The avatar and paddings are fixed, the text block below
/// them grows with the user's font scale so a large system font can't overflow
/// the tile.
SliverGridDelegateWithFixedCrossAxisCount _coachGridDelegate(
  BuildContext context,
) {
  final textBlock = MediaQuery.textScalerOf(context).scale(104);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: AppSpacing.sm,
    crossAxisSpacing: AppSpacing.sm,
    mainAxisExtent: 96 + textBlock,
  );
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach, required this.onTap});

  final PublicCoach coach;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = coach.headline?.isNotEmpty == true
        ? coach.headline!
        : coach.locationLabel ?? 'Huấn luyện viên';
    final experience = coach.experienceYears != null
        ? ' · ${coach.experienceYears} năm KN'
        : '';
    final hasReviews = coach.totalReviews > 0;
    final extraSports = coach.sports.length - 1;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            coach.fullName,
            style: AppTextStyles.cardTitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (coach.sports.isNotEmpty)
                Flexible(
                  child: AppBadge(
                    label: coach.sports.first.name,
                    tone: AppBadgeTone.brand,
                  ),
                ),
              if (extraSports > 0) ...[
                const SizedBox(width: AppSpacing.xxs),
                AppBadge(label: '+$extraSports', tone: AppBadgeTone.neutral),
              ] else if (coach.isOnlineAvailable) ...[
                const SizedBox(width: AppSpacing.xxs),
                const AppBadge(label: 'Online', tone: AppBadgeTone.info),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasReviews ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 14,
                color: hasReviews ? AppColors.warning : AppColors.textSecondary,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  hasReviews
                      ? '${coach.rating.toStringAsFixed(1)} '
                            '(${coach.totalReviews})$experience'
                      : 'Chưa có đánh giá',
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

/// Loading placeholder shaped like the coach grid above.
class _CoachGridSkeleton extends StatelessWidget {
  const _CoachGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.xxs,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: _coachGridDelegate(context),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Column(
            children: [
              AppSkeletonBox(width: 56, height: 56, shape: BoxShape.circle),
              SizedBox(height: AppSpacing.xs),
              AppSkeletonBox(
                width: 96,
                height: 12,
                radius: AppSpacing.radiusXs,
              ),
              SizedBox(height: AppSpacing.xxs),
              AppSkeletonBox(
                width: 72,
                height: 10,
                radius: AppSpacing.radiusXs,
              ),
              Spacer(),
              AppSkeletonBox(
                width: 64,
                height: 18,
                radius: AppSpacing.radiusFull,
              ),
              SizedBox(height: AppSpacing.xs),
              AppSkeletonBox(
                width: 80,
                height: 10,
                radius: AppSpacing.radiusXs,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
