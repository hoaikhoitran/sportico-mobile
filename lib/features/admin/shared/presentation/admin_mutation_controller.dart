import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';

/// Tracks which admin mutations are in flight, keyed by `<action>:<entityId>`.
///
/// Screen data (the list/detail providers) and one-off mutations are kept
/// apart on purpose: approving one package must not throw the whole list back
/// into a loading state. Screens watch this to disable a button and show an
/// inline spinner while its action runs.
///
/// [run] is also the duplicate-submit guard — a second tap on a key that is
/// already running is dropped instead of firing a second request.
class AdminMutationController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool isBusy(String key) => state.contains(key);

  /// Runs [action] under [key]. Returns the error to display, or null on
  /// success. [onSuccess] runs before the busy flag clears, so a list refresh
  /// completes while the button is still disabled.
  Future<ApiError?> run<T>(
    String key,
    Future<ApiResult<T>> Function() action, {
    FutureOr<void> Function(T data)? onSuccess,
  }) async {
    if (state.contains(key)) return null;
    state = {...state, key};

    try {
      final result = await action();
      switch (result) {
        case ApiSuccess(:final data):
          await onSuccess?.call(data);
          return null;
        case ApiFailure(:final error):
          return error;
      }
    } finally {
      // The notifier may already be disposed if the admin logged out mid-call.
      if (ref.mounted) {
        state = {...state}..remove(key);
      }
    }
  }
}

final adminMutationControllerProvider =
    NotifierProvider.autoDispose<AdminMutationController, Set<String>>(
      AdminMutationController.new,
    );

/// Convenience: is this specific action running right now?
final adminMutationBusyProvider = Provider.autoDispose.family<bool, String>((
  ref,
  key,
) {
  return ref.watch(adminMutationControllerProvider).contains(key);
});

/// Key helper so an id can never collide across two different actions.
String adminMutationKey(String action, String id) => '$action:$id';

/// Errors surfaced by [AdminMutationController.run].
typedef AdminMutationError = ApiError;
