import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/paged_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../data/models/app_notification.dart';
import '../data/notification_api.dart';

/// Unread badge count. Consumers invalidate after read actions.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final result = await ref.watch(notificationApiProvider).unreadCount();
  return switch (result) {
    ApiSuccess(:final data) => data,
    // Badge failures must never break the host screen.
    ApiFailure() => 0,
  };
});

class NotificationsController
    extends AsyncNotifier<PagedListState<AppNotification>> {
  @override
  Future<PagedListState<AppNotification>> build() =>
      _fetchPage(1).then(PagedListState.fromFirstPage);

  Future<PagedResult<AppNotification>> _fetchPage(int pageNumber) async {
    final result = await ref
        .read(notificationApiProvider)
        .list(pageNumber: pageNumber);
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    ref.invalidate(unreadCountProvider);
    state = await AsyncValue.guard(
      () => _fetchPage(1).then(PagedListState.fromFirstPage),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    try {
      final page = await _fetchPage(current.pageNumber + 1);
      state = AsyncData(current.appendPage(page));
    } on Object {
      state = AsyncData(current.withLoadingMore(false));
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;
    final result = await ref
        .read(notificationApiProvider)
        .markRead(notification.id);
    if (result.isSuccess) {
      _markLocally({notification.id});
      ref.invalidate(unreadCountProvider);
    }
  }

  Future<void> markAllRead() async {
    final result = await ref.read(notificationApiProvider).markAllRead();
    if (result.isSuccess) {
      final current = state.value;
      if (current != null) {
        _markLocally(current.items.map((n) => n.id).toSet());
      }
      ref.invalidate(unreadCountProvider);
    }
  }

  void _markLocally(Set<String> ids) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      PagedListState(
        items: [
          for (final n in current.items)
            ids.contains(n.id)
                ? AppNotification(
                    id: n.id,
                    title: n.title,
                    content: n.content,
                    type: n.type,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n,
        ],
        pageNumber: current.pageNumber,
        hasNext: current.hasNext,
        totalCount: current.totalCount,
      ),
    );
  }
}

final notificationsControllerProvider =
    AsyncNotifierProvider<
      NotificationsController,
      PagedListState<AppNotification>
    >(NotificationsController.new);
