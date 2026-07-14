import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/core/network/api_error.dart';
import 'package:group_prj/core/utils/paged_list_state.dart';
import 'package:group_prj/features/admin/shared/models/admin_status.dart';
import 'package:group_prj/features/admin/users/data/admin_users_api.dart';
import 'package:group_prj/features/admin/users/data/models/admin_user.dart';
import 'package:group_prj/features/admin/users/presentation/admin_users_controller.dart';

import 'support/fake_admin_apis.dart';

ProviderContainer _container(FakeAdminUsersApi api) {
  final container = ProviderContainer(
    overrides: [adminUsersApiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  // The admin providers are autoDispose (they drop their data when the admin
  // area is closed), so a test has to hold a subscription the way a mounted
  // screen would.
  container.listen(adminUsersControllerProvider, (_, _) {}, onError: (_, _) {});
  return container;
}

/// Waits for the controller to produce a value or an error.
///
/// Not `!isLoading`: Riverpod retries a failed provider, so an errored state
/// can report `isLoading` again while it re-runs.
Future<void> _settled(ProviderContainer container) async {
  while (true) {
    final state = container.read(adminUsersControllerProvider);
    if (state.hasValue || state.hasError) return;
    await Future<void>.delayed(Duration.zero);
  }
}

/// Waits for a successful first page.
Future<PagedListState<AdminUser>> _loaded(ProviderContainer container) async {
  await _settled(container);
  return container.read(adminUsersControllerProvider).requireValue;
}

void main() {
  test('starts in loading and then serves the first page', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1'), adminUser('u-2')],
      },
    );
    final container = _container(api);

    expect(
      container.read(adminUsersControllerProvider),
      isA<AsyncLoading<PagedListState<AdminUser>>>(),
    );

    final state = await _loaded(container);
    expect(state.items, hasLength(2));
    expect(state.pageNumber, 1);
    expect(state.totalCount, 2);
  });

  test('an API failure surfaces as an error state, not an empty list', () async {
    final api = FakeAdminUsersApi(pages: const {}, failList: true);
    final container = _container(api);

    await _settled(container);

    final state = container.read(adminUsersControllerProvider);
    expect(state, isA<AsyncError<PagedListState<AdminUser>>>());
    // The screen must be able to show the backend's message, not a blank list.
    expect((state as AsyncError).error, isA<ApiError>());
    expect((state.error as ApiError).isForbidden, isTrue);
  });

  test('loadMore appends the next page and keeps the existing items', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1'), adminUser('u-2')],
        2: [adminUser('u-3')],
      },
    );
    final container = _container(api);
    await _loaded(container);

    final controller = container.read(adminUsersControllerProvider.notifier);
    await controller.loadMore();

    final state = container.read(adminUsersControllerProvider).requireValue;
    expect(state.items.map((u) => u.id), ['u-1', 'u-2', 'u-3']);
    expect(state.pageNumber, 2);
    expect(state.hasNext, isFalse);
  });

  test('a next-page failure keeps the loaded items on screen', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1')],
        2: [adminUser('u-2')],
      },
      failOnPage: 2,
    );
    final container = _container(api);
    await _loaded(container);

    final controller = container.read(adminUsersControllerProvider.notifier);
    await controller.loadMore();

    final state = container.read(adminUsersControllerProvider);
    expect(state, isA<AsyncData<PagedListState<AdminUser>>>());
    expect(state.requireValue.items.map((u) => u.id), ['u-1']);
    expect(state.requireValue.loadingMore, isFalse);
  });

  test('loadMore is dropped when there is no further page', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1')],
      },
    );
    final container = _container(api);
    await _loaded(container);
    final callsAfterFirstLoad = api.listCalls;

    await container.read(adminUsersControllerProvider.notifier).loadMore();

    // No duplicate request when the list is already complete.
    expect(api.listCalls, callsAfterFirstLoad);
  });

  test('search and filters are sent to the backend', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1')],
      },
    );
    final container = _container(api);
    await _loaded(container);

    final controller = container.read(adminUsersControllerProvider.notifier);
    await controller.search('khôi');
    await controller.setRole(AdminRoles.coach);
    await controller.setStatus(AdminUserStatus.banned);

    final last = api.filtersSeen.last;
    expect(last.search, 'khôi');
    expect(last.role, AdminRoles.coach);
    expect(last.status, AdminUserStatus.banned);
    expect(controller.hasActiveFilters, isTrue);
  });

  test('clearFilters resets to the unfiltered first page', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1'), adminUser('u-2')],
      },
    );
    final container = _container(api);
    await _loaded(container);

    final controller = container.read(adminUsersControllerProvider.notifier);
    await controller.search('khôi');
    expect(
      container.read(adminUsersControllerProvider).requireValue.items.first.id,
      'filtered',
    );

    await controller.clearFilters();

    expect(controller.hasActiveFilters, isFalse);
    expect(api.filtersSeen.last.search, isEmpty);
    expect(api.filtersSeen.last.role, isNull);
    expect(
      container.read(adminUsersControllerProvider).requireValue.items,
      hasLength(2),
    );
  });

  test('refresh keeps the active filter instead of resetting it', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1')],
      },
    );
    final container = _container(api);
    await _loaded(container);

    final controller = container.read(adminUsersControllerProvider.notifier);
    await controller.search('khôi');
    await controller.refresh();

    expect(api.filtersSeen.last.search, 'khôi');
  });

  test('a successful deactivation refreshes the list', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1')],
      },
    );
    final container = _container(api);
    await _loaded(container);
    final callsBefore = api.listCalls;

    final error = await container
        .read(adminUsersControllerProvider.notifier)
        .deactivate('u-1');

    expect(error, isNull);
    expect(api.deactivateCalls, 1);
    // The list is refetched only after the backend confirmed.
    expect(api.listCalls, callsBefore + 1);
  });

  test('creating a user refreshes the list', () async {
    final api = FakeAdminUsersApi(
      pages: {
        1: [adminUser('u-1')],
      },
    );
    final container = _container(api);
    await _loaded(container);
    final callsBefore = api.listCalls;

    final error = await container
        .read(adminUsersControllerProvider.notifier)
        .create(
          const AdminCreateUserRequest(
            email: 'new@sportico.vn',
            fullName: 'Người Mới',
            password: 'password123',
            status: AdminUserStatus.active,
            roles: ['learner'],
          ),
        );

    expect(error, isNull);
    expect(api.createCalls, 1);
    expect(api.listCalls, callsBefore + 1);
  });
}
