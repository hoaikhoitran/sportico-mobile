import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/retry_policy.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../data/admin_users_api.dart';
import '../data/models/admin_user.dart';

/// User directory: debounced search + role/status filters + infinite scroll.
class AdminUsersController extends AsyncNotifier<PagedListState<AdminUser>> {
  AdminUserFilter _filter = const AdminUserFilter();

  AdminUserFilter get filter => _filter;
  bool get hasActiveFilters => _filter.hasActiveFilters;

  @override
  Future<PagedListState<AdminUser>> build() => _fetchFirstPage();

  AdminUsersApi get _api => ref.read(adminUsersApiProvider);

  Future<PagedListState<AdminUser>> _fetchFirstPage() async {
    final result = await _api.list(
      filter: _filter,
      pageSize: AppConfig.defaultPageSize,
    );
    return switch (result) {
      ApiSuccess(:final data) => PagedListState.fromFirstPage(data),
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> search(String keyword) {
    _filter = _filter.copyWith(search: keyword.trim());
    return _reload();
  }

  Future<void> setRole(String? role) {
    _filter = role == null
        ? _filter.copyWith(clearRole: true)
        : _filter.copyWith(role: role);
    return _reload();
  }

  Future<void> setStatus(AdminUserStatus? status) {
    _filter = status == null
        ? _filter.copyWith(clearStatus: true)
        : _filter.copyWith(status: status);
    return _reload();
  }

  Future<void> clearFilters() {
    _filter = const AdminUserFilter();
    return _reload();
  }

  /// Refetches page 1 and keeps every active filter.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    final result = await _api.list(
      filter: _filter,
      pageNumber: current.pageNumber + 1,
      pageSize: AppConfig.defaultPageSize,
    );
    switch (result) {
      case ApiSuccess(:final data):
        state = AsyncData(current.appendPage(data));
      case ApiFailure():
        state = AsyncData(current.withLoadingMore(false));
    }
  }

  Future<ApiError?> create(AdminCreateUserRequest request) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('create-user', 'new'),
          () => _api.create(request),
          onSuccess: (_) => refresh(),
        );
  }

  Future<ApiError?> edit(String id, AdminUpdateUserRequest request) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('update-user', id),
          () => _api.update(id, request),
          onSuccess: (_) async {
            ref.invalidate(adminUserDetailProvider(id));
            await refresh();
          },
        );
  }

  /// `DELETE` deactivates the account (status → `inactive`); the row itself is
  /// kept by the backend. The list is only refreshed once the server confirms —
  /// no optimistic removal.
  Future<ApiError?> deactivate(String id) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('deactivate-user', id),
          () => _api.deactivate(id),
          onSuccess: (_) async {
            ref.invalidate(adminUserDetailProvider(id));
            await refresh();
          },
        );
  }
}

final adminUsersControllerProvider =
    AsyncNotifierProvider.autoDispose<
      AdminUsersController,
      PagedListState<AdminUser>
    >(AdminUsersController.new, retry: noRetry);

/// One user (`GET /api/admin/users/{id}`) — detail screen and edit prefill.
final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUser, String>((ref, id) async {
      final result = await ref.watch(adminUsersApiProvider).detail(id);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) => throw error,
      };
    }, retry: noRetry);
