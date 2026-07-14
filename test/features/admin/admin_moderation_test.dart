import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/features/admin/moderation/data/admin_moderation_api.dart';
import 'package:group_prj/features/admin/moderation/presentation/pending_packages_tab.dart';
import 'package:group_prj/features/admin/users/data/admin_users_api.dart';
import 'package:group_prj/features/training_packages/data/models/training_package.dart';

import 'support/fake_admin_apis.dart';

TrainingPackage _package() => TrainingPackage(
  id: 'pkg-1',
  coachId: 'c-1',
  sportId: 1,
  sportName: 'Cầu lông',
  title: 'Cầu lông cơ bản 10 buổi',
  price: 2000000,
  sessionCount: 10,
  durationDays: 30,
  status: PackageStatus.pending,
  createdAt: DateTime(2026, 3, 1),
);

Future<void> _pump(WidgetTester tester, FakeAdminModerationApi api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminModerationApiProvider.overrideWithValue(api),
        // The card resolves the coach name through the admin users endpoint.
        adminUsersApiProvider.overrideWithValue(
          FakeAdminUsersApi(
            pages: const {},
            details: {'c-1': adminUser('c-1', name: 'Trần Hoài Khôi')},
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: PendingPackagesTab())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty queue shows the empty state, not a blank list', (
    tester,
  ) async {
    await _pump(tester, FakeAdminModerationApi());

    expect(find.text('Không có gói tập chờ duyệt'), findsOneWidget);
    expect(find.text('Mọi gói tập đã được xử lý.'), findsOneWidget);
  });

  testWidgets('a pending package renders with its approve/reject actions', (
    tester,
  ) async {
    await _pump(tester, FakeAdminModerationApi(packages: [_package()]));

    expect(find.text('Cầu lông cơ bản 10 buổi'), findsOneWidget);
    expect(find.textContaining('2.000.000'), findsOneWidget);
    // The coach uuid is resolved to a name — an admin never reads a raw id.
    expect(find.textContaining('Trần Hoài Khôi'), findsOneWidget);
    expect(find.textContaining('c-1'), findsNothing);
    expect(find.text('Phê duyệt'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
  });

  testWidgets('rejecting requires a reason — an empty one is not submitted', (
    tester,
  ) async {
    final api = FakeAdminModerationApi(packages: [_package()]);
    await _pump(tester, api);

    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();

    // Submit the sheet with an empty reason.
    await tester.tap(
      find.widgetWithText(FilledButton, 'Từ chối').hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập lý do từ chối.'), findsOneWidget);
    // The backend requires a non-empty reason, so nothing was sent.
    expect(api.rejectPackageCalls, 0);
  });

  testWidgets('a rejection with a reason reaches the backend verbatim', (
    tester,
  ) async {
    final api = FakeAdminModerationApi(packages: [_package()]);
    await _pump(tester, api);

    await tester.tap(find.text('Từ chối'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Lịch tập chưa hợp lý');
    await tester.tap(
      find.widgetWithText(FilledButton, 'Từ chối').hitTestable(),
    );
    await tester.pumpAndSettle();

    expect(api.rejectPackageCalls, 1);
    expect(api.lastRejectReason, 'Lịch tập chưa hợp lý');
  });

  testWidgets('approving asks for confirmation first', (tester) async {
    final api = FakeAdminModerationApi(packages: [_package()]);
    await _pump(tester, api);

    await tester.tap(find.text('Phê duyệt'));
    await tester.pumpAndSettle();

    expect(find.text('Duyệt gói tập'), findsOneWidget);

    // Backing out must not touch the backend.
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(api.approvePackageCalls, 0);
  });

  testWidgets('both actions lock while an approval is in flight', (
    tester,
  ) async {
    final api = FakeAdminModerationApi(
      packages: [_package()],
      approveDelay: const Duration(milliseconds: 300),
    );
    await _pump(tester, api);

    await tester.tap(find.text('Phê duyệt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Phê duyệt'));
    await tester.pump(); // dialog closed, approval in flight

    // Approve shows a spinner and takes no further taps — a frantic double tap
    // cannot fire a second approval...
    final approve = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(approve.onPressed, isNull);
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    // ...and reject is locked too, so the same package cannot be approved and
    // rejected at once.
    final reject = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(reject.onPressed, isNull);

    await tester.pumpAndSettle();
    expect(api.approvePackageCalls, 1);
  });
}
