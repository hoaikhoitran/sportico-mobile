import '../network/paged_result.dart';

/// Accumulated state for infinite-scroll lists backed by `PagedResult<T>`.
class PagedListState<T> {
  const PagedListState({
    required this.items,
    required this.pageNumber,
    required this.hasNext,
    this.loadingMore = false,
    this.totalCount = 0,
  });

  final List<T> items;
  final int pageNumber;
  final bool hasNext;
  final bool loadingMore;
  final int totalCount;

  bool get isEmpty => items.isEmpty;

  factory PagedListState.fromFirstPage(PagedResult<T> page) => PagedListState(
    items: page.items,
    pageNumber: page.pageNumber,
    hasNext: page.hasNext,
    totalCount: page.totalCount,
  );

  PagedListState<T> appendPage(PagedResult<T> page) => PagedListState(
    items: [...items, ...page.items],
    pageNumber: page.pageNumber,
    hasNext: page.hasNext,
    totalCount: page.totalCount,
  );

  PagedListState<T> withLoadingMore(bool value) => PagedListState(
    items: items,
    pageNumber: pageNumber,
    hasNext: hasNext,
    loadingMore: value,
    totalCount: totalCount,
  );
}
