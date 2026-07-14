import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_result.dart';
import '../../../../core/network/retry_policy.dart';
import '../data/admin_dashboard_api.dart';
import '../data/models/admin_dashboard.dart';

/// Dashboard data + the active period filter.
class AdminDashboardController extends AsyncNotifier<AdminDashboard> {
  DashboardFilter _filter = DashboardFilter.allTime;

  DashboardFilter get filter => _filter;

  @override
  Future<AdminDashboard> build() => _fetch();

  Future<AdminDashboard> _fetch() async {
    final result = await ref.read(adminDashboardApiProvider).load(_filter);
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiFailure(:final error) => throw error,
    };
  }

  Future<void> setFilter(DashboardFilter filter) async {
    _filter = filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Pull-to-refresh: keeps the current period.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }
}

final adminDashboardControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminDashboardController, AdminDashboard>(
      AdminDashboardController.new,
      retry: noRetry,
    );
