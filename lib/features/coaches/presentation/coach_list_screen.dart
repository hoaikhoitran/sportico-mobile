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
      appBar: AppBar(title: const Text('Huấn luyện viên')),
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
                          child: ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenH,
                              AppSpacing.xxs,
                              AppSpacing.screenH,
                              AppSpacing.xl,
                            ),
                            itemCount:
                                value.items.length + (value.hasNext ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              if (index >= value.items.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final coach = value.items[index];
                              return _CoachCard(
                                coach: coach,
                                onTap: () => context.push(
                                  RouteNames.coachDetailPath(coach.coachId),
                                ),
                              );
                            },
                          ),
                        ),
                AsyncError(:final error) => AppErrorState(
                  error: error is ApiError ? error : null,
                  onRetry: () =>
                      ref.read(coachListControllerProvider.notifier).refresh(),
                ),
                _ => const AppSkeletonList(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.coach, required this.onTap});

  final PublicCoach coach;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
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
                if (coach.headline?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    coach.headline!,
                    style: AppTextStyles.bodySecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xxs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    for (final sport in coach.sports)
                      AppBadge(label: sport.name, tone: AppBadgeTone.brand),
                    if (coach.isOnlineAvailable)
                      const AppBadge(label: 'Online', tone: AppBadgeTone.info),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
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
                        '${coach.rating.toStringAsFixed(1)} '
                        '(${coach.totalReviews})',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    if (coach.experienceYears != null) ...[
                      Text(
                        '${coach.experienceYears} năm KN',
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
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
