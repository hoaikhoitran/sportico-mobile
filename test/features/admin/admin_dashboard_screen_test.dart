import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/core/widgets/app_error_state.dart';
import 'package:group_prj/core/widgets/app_skeleton.dart';
import 'package:group_prj/features/admin/dashboard/data/admin_dashboard_api.dart';
import 'package:group_prj/features/admin/dashboard/presentation/admin_dashboard_screen.dart';

import 'support/fake_admin_apis.dart';

Future<void> _pump(WidgetTester tester, FakeAdminDashboardApi api) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [adminDashboardApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: AdminDashboardScreen()),
    ),
  );
}

void main() {
  testWidgets('shows a loading skeleton before the KPIs arrive', (
    tester,
  ) async {
    await _pump(tester, FakeAdminDashboardApi(dashboard: sampleDashboard()));

    // First frame: the request is still in flight.
    expect(find.byType(AppSkeletonList), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(AppSkeletonList), findsNothing);
  });

  testWidgets('renders the KPI values returned by the backend', (tester) async {
    await _pump(tester, FakeAdminDashboardApi(dashboard: sampleDashboard()));
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Kỳ báo cáo: Toàn thời gian'), findsOneWidget);

    // Counters come straight from the DTO — nothing is computed on the client.
    expect(find.text('120'), findsOneWidget); // totalUsers
    expect(find.text('30'), findsOneWidget); // totalCoaches

    // Money is formatted as Vietnamese đồng.
    expect(find.textContaining('150.000.000'), findsOneWidget);
    expect(find.textContaining('₫'), findsWidgets);

    // Further down: the withdrawal queue counters and the shortcuts.
    // `.last` is the vertical content list — `.first` is the period chip row.
    await tester.scrollUntilVisible(
      find.text('Yêu cầu rút tiền'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget); // pendingWithdrawals
    expect(find.text('Chờ duyệt'), findsOneWidget);
  });

  testWidgets('a failed load shows a retryable error state', (tester) async {
    final api = FakeAdminDashboardApi(error: forbiddenError);
    await _pump(tester, api);
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorState), findsOneWidget);
    expect(find.text('Không tải được dữ liệu'), findsOneWidget);

    // Retry re-issues the request instead of leaving the admin stuck.
    final callsBefore = api.filtersSeen.length;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(api.filtersSeen.length, greaterThan(callsBefore));
  });

  testWidgets('changing the period sends FromDate/ToDate to the backend', (
    tester,
  ) async {
    final api = FakeAdminDashboardApi(dashboard: sampleDashboard());
    await _pump(tester, api);
    await tester.pumpAndSettle();

    expect(api.filtersSeen.single.isAllTime, isTrue);

    await tester.tap(find.text('7 ngày'));
    await tester.pumpAndSettle();

    final filter = api.filtersSeen.last;
    expect(filter.isAllTime, isFalse);
    expect(filter.fromDate, isNotNull);
    expect(filter.toDate, isNotNull);
    expect(find.text('Kỳ báo cáo: 7 ngày qua'), findsOneWidget);
  });
}
