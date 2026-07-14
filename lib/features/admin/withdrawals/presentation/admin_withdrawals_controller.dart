import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/retry_policy.dart';
import '../../../../core/utils/paged_list_state.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../data/admin_withdrawals_api.dart';
import '../data/models/withdrawal_request.dart';

/// Withdrawal queue: all statuses, or one selected status.
///
/// `null` status means "all" and uses `GET /withdrawal-requests`; picking
/// `pending` uses the dedicated `/pending` endpoint.
class AdminWithdrawalsController
    extends AsyncNotifier<PagedListState<WithdrawalRequest>> {
  WithdrawalStatus? _status = WithdrawalStatus.pending;

  WithdrawalStatus? get statusFilter => _status;
  bool get hasActiveFilters => _status != null;

  @override
  Future<PagedListState<WithdrawalRequest>> build() => _fetchFirstPage();

  AdminWithdrawalsApi get _api => ref.read(adminWithdrawalsApiProvider);

  bool get _usePendingEndpoint => _status == WithdrawalStatus.pending;

  Future<PagedListState<WithdrawalRequest>> _fetchFirstPage() async {
    final result = await _api.list(
      status: _usePendingEndpoint ? null : _status,
      pendingOnly: _usePendingEndpoint,
      pageSize: AppConfig.defaultPageSize,
    );
    return switch (result) {
      ApiSuccess(:final data) => PagedListState.fromFirstPage(data),
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> setStatus(WithdrawalStatus? status) async {
    _status = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> clearFilters() => setStatus(null);

  /// Refetches page 1 and keeps the selected status.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasNext || current.loadingMore) return;

    state = AsyncData(current.withLoadingMore(true));
    final result = await _api.list(
      status: _usePendingEndpoint ? null : _status,
      pendingOnly: _usePendingEndpoint,
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
}

final adminWithdrawalsControllerProvider =
    AsyncNotifierProvider.autoDispose<
      AdminWithdrawalsController,
      PagedListState<WithdrawalRequest>
    >(AdminWithdrawalsController.new, retry: noRetry);

/// One withdrawal, with the actions its current status allows.
///
/// Every action refetches this provider on success, and invalidates the list so
/// the queue reflects the new status — without resetting the list's filter or
/// forcing the whole admin shell to reload.
class AdminWithdrawalDetailController extends AsyncNotifier<WithdrawalRequest> {
  AdminWithdrawalDetailController(this.withdrawalId);

  final String withdrawalId;

  @override
  Future<WithdrawalRequest> build() => _fetch();

  AdminWithdrawalsApi get _api => ref.read(adminWithdrawalsApiProvider);

  Future<WithdrawalRequest> _fetch() async {
    final result = await _api.detail(withdrawalId);
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<ApiError?> _run(
    String action,
    Future<ApiResult<WithdrawalRequest>> Function() call,
  ) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey(action, withdrawalId),
          call,
          onSuccess: (updated) {
            // The action returns the fresh entity — no second round-trip.
            state = AsyncData(updated);
            // The queue must show the new status, but keeps its own filter.
            ref.invalidate(adminWithdrawalsControllerProvider);
          },
        );
  }

  Future<ApiError?> approve() =>
      _run('approve-withdrawal', () => _api.approve(withdrawalId));

  Future<ApiError?> reject(String? adminNote) => _run(
    'reject-withdrawal',
    () => _api.reject(
      withdrawalId,
      adminNote: (adminNote == null || adminNote.trim().isEmpty)
          ? null
          : adminNote.trim(),
    ),
  );

  Future<ApiError?> markPaid() =>
      _run('mark-paid-withdrawal', () => _api.markPaid(withdrawalId));

  Future<ApiError?> refreshPayoutStatus() =>
      _run('refresh-payout', () => _api.refreshPayoutStatus(withdrawalId));

  Future<ApiError?> retryPayout() =>
      _run('retry-payout', () => _api.retryPayout(withdrawalId));
}

final adminWithdrawalDetailProvider = AsyncNotifierProvider.autoDispose
    .family<AdminWithdrawalDetailController, WithdrawalRequest, String>(
      AdminWithdrawalDetailController.new,
      retry: noRetry,
    );

/// `GET /api/admin/withdrawal-requests/{id}/receipt`.
final adminWithdrawalReceiptProvider = FutureProvider.autoDispose
    .family<WithdrawalReceipt, String>((ref, id) async {
      final result = await ref.watch(adminWithdrawalsApiProvider).receipt(id);
      return switch (result) {
        ApiSuccess(:final data) => data,
        ApiFailure(:final error) => throw error,
      };
    }, retry: noRetry);
