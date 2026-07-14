import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/retry_policy.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../data/admin_moderation_api.dart';
import '../data/models/coach_payout_account.dart';

/// Coach payout accounts awaiting verification
/// (`GET /api/admin/coach-payout-accounts/pending`). The endpoint takes only
/// paging — there are no filters to expose.
class PayoutAccountsController
    extends AsyncNotifier<PagedListState<CoachPayoutAccount>> {
  @override
  Future<PagedListState<CoachPayoutAccount>> build() => _fetchFirstPage();

  AdminModerationApi get _api => ref.read(adminModerationApiProvider);

  Future<PagedListState<CoachPayoutAccount>> _fetchFirstPage() async {
    final result = await _api.pendingPayoutAccounts(
      pageSize: AppConfig.defaultPageSize,
    );
    return switch (result) {
      ApiSuccess(:final data) => PagedListState.fromFirstPage(data),
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    final result = await _api.pendingPayoutAccounts(
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

  Future<ApiError?> verify(String id) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('verify-payout-account', id),
          () => _api.verifyPayoutAccount(id),
          onSuccess: (_) => refresh(),
        );
  }

  /// The rejection note is optional on the backend, so an empty note is sent
  /// as `null` rather than an empty string.
  Future<ApiError?> reject(String id, String? note) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('reject-payout-account', id),
          () => _api.rejectPayoutAccount(
            id,
            note: (note == null || note.trim().isEmpty) ? null : note.trim(),
          ),
          onSuccess: (_) => refresh(),
        );
  }

  /// No `GET /coach-payout-accounts/{id}` on the admin API — the detail screen
  /// reads the account the list already loaded.
  CoachPayoutAccount? findById(String id) {
    final items = state.value?.items;
    if (items == null) return null;
    for (final account in items) {
      if (account.id == id) return account;
    }
    return null;
  }
}

final payoutAccountsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      PayoutAccountsController,
      PagedListState<CoachPayoutAccount>
    >(PayoutAccountsController.new, retry: noRetry);
