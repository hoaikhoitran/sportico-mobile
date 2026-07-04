import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/network/api_error.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../data/sport_options_provider.dart';
import 'package_list_controller.dart';
import 'widgets/package_card.dart';

/// Public training package catalog (works signed-out too).
class PackageListScreen extends ConsumerStatefulWidget {
  const PackageListScreen({super.key});

  @override
  ConsumerState<PackageListScreen> createState() => _PackageListScreenState();
}

class _PackageListScreenState extends ConsumerState<PackageListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      ref.read(packageListControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    // Rebuild so the clear button appears/disappears with the text.
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(packageListControllerProvider.notifier).search(value);
    });
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    ref.read(packageListControllerProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(packageListControllerProvider);
    final controller = ref.read(packageListControllerProvider.notifier);
    final sports = ref.watch(sportOptionsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Gói tập')),
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
                  hintText: 'Tìm gói tập, môn thể thao…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (sports.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenH,
                  ),
                  children: [
                    for (final (label, id) in [
                      ('Tất cả', null),
                      for (final sport in sports) (sport.name, sport.id),
                    ]) ...[
                      ChoiceChip(
                        label: Text(label),
                        selected: controller.sportId == id,
                        onSelected: (_) => controller.setSport(id),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: switch (listState) {
                AsyncData(:final value) =>
                  value.isEmpty
                      ? (controller.hasFilter
                            ? AppEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'Không tìm thấy gói tập',
                                message:
                                    'Không có gói tập nào khớp với tìm kiếm '
                                    'hoặc bộ lọc hiện tại.',
                                actionLabel: 'Xóa bộ lọc',
                                onAction: _clearFilters,
                              )
                            : const AppEmptyState(
                                icon: Icons.fitness_center_rounded,
                                title: 'Chưa có gói tập nào',
                                message:
                                    'Hiện chưa có gói tập nào được mở bán. '
                                    'Quay lại sau nhé!',
                              ))
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(packageListControllerProvider.notifier)
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
                              final package = value.items[index];
                              return PackageCard(
                                package: package,
                                onTap: () => context.push(
                                  RouteNames.packageDetailPath(package.id),
                                ),
                              );
                            },
                          ),
                        ),
                AsyncError(:final error) => AppErrorState(
                  error: error is ApiError ? error : null,
                  onRetry: () => ref
                      .read(packageListControllerProvider.notifier)
                      .refresh(),
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
