import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/features/admin/shared/models/admin_status.dart';
import 'package:group_prj/features/admin/users/data/admin_users_api.dart';
import 'package:group_prj/features/admin/users/presentation/admin_user_detail_screen.dart';

import 'support/fake_admin_apis.dart';

Future<FakeAdminUsersApi> _pumpDetail(
  WidgetTester tester, {
  AdminUserStatus status = AdminUserStatus.active,
}) async {
  final api = FakeAdminUsersApi(
    pages: const {},
    details: {'u-1': adminUser('u-1', name: 'Trần Hoài Khôi', status: status)},
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminUsersApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: AdminUserDetailScreen(userId: 'u-1')),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('the destructive action names the user before anything happens', (
    tester,
  ) async {
    final api = await _pumpDetail(tester);

    await tester.tap(find.text('Ngừng hoạt động tài khoản'));
    await tester.pumpAndSettle();

    // The dialog identifies exactly whose account is affected.
    expect(find.textContaining('Trần Hoài Khôi'), findsWidgets);
    expect(find.textContaining('u-1@sportico.vn'), findsWidgets);
    // And it is honest about what the backend does: a deactivation, not a
    // permanent delete.
    expect(find.textContaining('ngừng hoạt động'), findsOneWidget);
    expect(find.textContaining('vẫn được giữ lại'), findsOneWidget);

    expect(api.deactivateCalls, 0);
  });

  testWidgets('cancelling the confirmation calls no endpoint', (tester) async {
    final api = await _pumpDetail(tester);

    await tester.tap(find.text('Ngừng hoạt động tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();

    expect(api.deactivateCalls, 0);
  });

  testWidgets('confirming deactivates the account exactly once', (
    tester,
  ) async {
    final api = await _pumpDetail(tester);

    await tester.tap(find.text('Ngừng hoạt động tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Ngừng hoạt động'));
    await tester.pumpAndSettle();

    expect(api.deactivateCalls, 1);
    expect(find.text('Đã ngừng hoạt động tài khoản.'), findsOneWidget);
  });

  testWidgets('an already inactive account offers no deactivate action', (
    tester,
  ) async {
    await _pumpDetail(tester, status: AdminUserStatus.inactive);

    expect(find.text('Ngừng hoạt động tài khoản'), findsNothing);
    expect(find.text('Ngừng hoạt động'), findsOneWidget); // the status chip
  });
}
