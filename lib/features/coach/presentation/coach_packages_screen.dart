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
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../training_packages/data/models/training_package.dart';
import 'coach_packages_controller.dart';

/// Coach package management: list own packages, filter by status,
/// create / edit (while not published) / archive.
class CoachPackagesScreen extends ConsumerStatefulWidget {
  const CoachPackagesScreen({super.key});

  @override
  ConsumerState<CoachPackagesScreen> createState() =>
      _CoachPackagesScreenState();
}

class _CoachPackagesScreenState extends ConsumerState<CoachPackagesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        ref.read(coachPackagesControllerProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _confirmArchive(TrainingPackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu trữ gói tập'),
        content: Text(
          'Gói "${package.title}" sẽ ngừng hiển thị với người tập. '
          'Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Lưu trữ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(coachPackagesControllerProvider.notifier)
        .archive(package.id);
    if (!mounted) return;
    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
    } else {
      AppSnackBar.success(context, 'Đã lưu trữ gói tập.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(coachPackagesControllerProvider);
    final controller = ref.read(coachPackagesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Gói tập của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.coachPackageCreate),
        backgroundColor: AppColors.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo gói tập'),
      ),
      body: SafeArea(
        child: Column(
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
                    ('Chờ duyệt', PackageStatus.pending),
                    ('Đang mở bán', PackageStatus.published),
                    ('Bị từ chối', PackageStatus.rejected),
                    ('Đã lưu trữ', PackageStatus.archived),
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
                          icon: Icons.inventory_2_outlined,
                          title: 'Chưa có gói tập nào',
                          message:
                              'Tạo gói tập đầu tiên với lịch tập cố định. Gói sẽ '
                              'được quản trị viên duyệt trước khi mở bán.',
                          actionLabel: 'Tạo gói tập',
                          onAction: () =>
                              context.push(RouteNames.coachPackageCreate),
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
                              96,
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
                              final package = value.items[index];
                              return _CoachPackageCard(
                                package: package,
                                onEdit: () => context.push(
                                  RouteNames.coachPackageEditPath(package.id),
                                ),
                                onArchive: () => _confirmArchive(package),
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
        ),
      ),
    );
  }
}

class _CoachPackageCard extends StatelessWidget {
  const _CoachPackageCard({
    required this.package,
    required this.onEdit,
    required this.onArchive,
  });

  final TrainingPackage package;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  /// Backend blocks updates on `published`; archived is terminal here.
  bool get _canEdit =>
      package.status == PackageStatus.pending ||
      package.status == PackageStatus.rejected;

  bool get _canArchive => package.status != PackageStatus.archived;

  AppBadgeTone get _statusTone => switch (package.status) {
    PackageStatus.pending => AppBadgeTone.warning,
    PackageStatus.published => AppBadgeTone.success,
    PackageStatus.rejected => AppBadgeTone.danger,
    PackageStatus.archived => AppBadgeTone.neutral,
    PackageStatus.unknown => AppBadgeTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: _canEdit ? onEdit : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  package.title,
                  style: AppTextStyles.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppBadge(label: package.status.label, tone: _statusTone),
              if (_canEdit || _canArchive)
                SizedBox(
                  width: 32,
                  height: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (action) => switch (action) {
                      'edit' => onEdit(),
                      'archive' => onArchive(),
                      _ => null,
                    },
                    itemBuilder: (context) => [
                      if (_canEdit)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Chỉnh sửa'),
                        ),
                      if (_canArchive)
                        const PopupMenuItem(
                          value: 'archive',
                          child: Text('Lưu trữ'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${package.sportName} · ${package.sessionCount} buổi · '
            '${package.isOnline ? 'Online' : 'Trực tiếp'}',
            style: AppTextStyles.bodySecondary,
          ),
          if (package.status == PackageStatus.rejected &&
              package.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'Lý do từ chối: ${package.rejectionReason}',
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(package.priceLabel, style: AppTextStyles.price),
              if (_canEdit)
                Text('Nhấn để chỉnh sửa', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
