import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/retry_policy.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../data/admin_settings_api.dart';
import '../data/models/platform_commission.dart';

/// The platform commission rate.
class AdminCommissionController extends AsyncNotifier<PlatformCommission> {
  @override
  Future<PlatformCommission> build() => _fetch();

  Future<PlatformCommission> _fetch() async {
    final result = await ref.read(adminSettingsApiProvider).commission();
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  /// Sends the new rate as a percent (0–100) and adopts the value the backend
  /// echoes back, so the form always shows the stored truth.
  Future<ApiError?> save(num commissionPercent) {
    return ref
        .read(adminMutationControllerProvider.notifier)
        .run(
          adminMutationKey('update-commission', 'platform'),
          () => ref
              .read(adminSettingsApiProvider)
              .updateCommission(commissionPercent),
          onSuccess: (updated) => state = AsyncData(updated),
        );
  }
}

final adminCommissionControllerProvider =
    AsyncNotifierProvider.autoDispose<
      AdminCommissionController,
      PlatformCommission
    >(AdminCommissionController.new, retry: noRetry);

/// Key of the commission mutation (single global setting → constant id).
const adminCommissionMutationKey = 'update-commission:platform';
