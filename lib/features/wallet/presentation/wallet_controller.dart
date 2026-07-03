import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/paged_result.dart';
import '../../../core/utils/paged_list_state.dart';
import '../data/models/coach_wallet.dart';
import '../data/wallet_api.dart';

final coachWalletProvider = FutureProvider.autoDispose<CoachWallet>((
  ref,
) async {
  final result = await ref.watch(walletApiProvider).wallet();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final error) => throw error,
  };
});

class WalletTransactionsController
    extends AsyncNotifier<PagedListState<WalletTransaction>> {
  @override
  Future<PagedListState<WalletTransaction>> build() =>
      _fetchPage(1).then(PagedListState.fromFirstPage);

  Future<PagedResult<WalletTransaction>> _fetchPage(int pageNumber) async {
    final result = await ref
        .read(walletApiProvider)
        .transactions(pageNumber: pageNumber);
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    ref.invalidate(coachWalletProvider);
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
}

final walletTransactionsControllerProvider =
    AsyncNotifierProvider<
      WalletTransactionsController,
      PagedListState<WalletTransaction>
    >(WalletTransactionsController.new);
