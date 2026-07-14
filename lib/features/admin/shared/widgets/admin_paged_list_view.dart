import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_skeleton.dart';

/// The one paginated list surface of the admin area.
///
/// Owns every state a paged screen must handle — initial loading skeleton,
/// content, empty, retryable error, pull-to-refresh, next-page spinner and the
/// "no more results" footer — so individual screens only describe a row.
///
/// [onLoadMore] is called once the viewport approaches the end; the controller
/// itself drops the call while a page is already in flight, so a fast scroll
/// cannot fire duplicate requests.
class AdminPagedListView<T> extends StatefulWidget {
  const AdminPagedListView({
    super.key,
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    this.header,
    this.totalLabelBuilder,
  });

  final AsyncValue<PagedListState<T>> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final void Function() onLoadMore;

  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;

  /// Pinned above the list (filter chips, search field…). Stays visible in
  /// every state so the user can always clear a filter that returned nothing.
  final Widget? header;

  /// Renders the `totalCount` returned by `PagedResult<T>`.
  final String Function(int totalCount)? totalLabelBuilder;

  @override
  State<AdminPagedListView<T>> createState() => _AdminPagedListViewState<T>();
}

class _AdminPagedListViewState<T> extends State<AdminPagedListView<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 400) {
        widget.onLoadMore();
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
    return Column(
      children: [
        ?widget.header,
        Expanded(
          child: switch (widget.state) {
            AsyncData(:final value) => _buildLoaded(value),
            AsyncError(:final error) => AppErrorState(
              error: error is ApiError ? error : null,
              onRetry: widget.onRefresh,
            ),
            _ => const AppSkeletonList(showDayHeaders: false),
          },
        ),
      ],
    );
  }

  Widget _buildLoaded(PagedListState<T> value) {
    if (value.isEmpty) {
      // Still scrollable so pull-to-refresh works on an empty result.
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.55,
              child: AppEmptyState(
                icon: widget.emptyIcon,
                title: widget.emptyTitle,
                message: widget.emptyMessage,
              ),
            ),
          ],
        ),
      );
    }

    final total = widget.totalLabelBuilder?.call(value.totalCount);
    // header row (optional) + items + footer
    final headerCount = total != null ? 1 : 0;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.xs,
          AppSpacing.screenH,
          AppSpacing.xxl,
        ),
        itemCount: headerCount + value.items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (headerCount == 1 && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Text(total!, style: AppTextStyles.caption),
            );
          }

          final itemIndex = index - headerCount;
          if (itemIndex < value.items.length) {
            return widget.itemBuilder(context, value.items[itemIndex]);
          }

          // Footer: next-page spinner, or the end-of-list marker.
          if (value.hasNext) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              child: Text('Đã hiển thị tất cả', style: AppTextStyles.caption),
            ),
          );
        },
      ),
    );
  }
}
