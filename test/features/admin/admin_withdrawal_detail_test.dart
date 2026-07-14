import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/features/admin/shared/models/admin_status.dart';
import 'package:group_prj/features/admin/users/data/admin_users_api.dart';
import 'package:group_prj/features/admin/withdrawals/data/admin_withdrawals_api.dart';
import 'package:group_prj/features/admin/withdrawals/data/models/withdrawal_request.dart';
import 'package:group_prj/features/admin/withdrawals/presentation/admin_withdrawal_detail_screen.dart';

import 'support/fake_admin_apis.dart';

WithdrawalRequest _withdrawal(WithdrawalStatus status, {String? payoutId}) {
  return WithdrawalRequest(
    id: 'w-1',
    coachId: 'c-1',
    coachWalletId: 'cw-1',
    amount: 2500000,
    status: status,
    payOsPayoutId: payoutId,
    createdAt: DateTime(2026, 3, 1),
  );
}

Future<FakeAdminWithdrawalsApi> _pumpDetail(
  WidgetTester tester,
  WithdrawalRequest withdrawal,
) async {
  final api = FakeAdminWithdrawalsApi(withdrawal: withdrawal);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminWithdrawalsApiProvider.overrideWithValue(api),
        adminUsersApiProvider.overrideWithValue(
          FakeAdminUsersApi(
            pages: const {},
            details: {'c-1': adminUser('c-1', name: 'Trần Hoài Khôi')},
          ),
        ),
      ],
      child: const MaterialApp(
        home: AdminWithdrawalDetailScreen(withdrawalId: 'w-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('a pending withdrawal offers approve and reject only', (
    tester,
  ) async {
    await _pumpDetail(tester, _withdrawal(WithdrawalStatus.pending));

    expect(find.textContaining('2.500.000'), findsOneWidget);
    expect(find.text('Chờ duyệt'), findsOneWidget);

    expect(find.text('Phê duyệt'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
    expect(find.text('Đánh dấu đã thanh toán'), findsNothing);
    expect(find.text('Thử thanh toán lại'), findsNothing);
    expect(find.text('Cập nhật trạng thái thanh toán'), findsNothing);
  });

  testWidgets('an approved withdrawal can be marked paid, never re-approved', (
    tester,
  ) async {
    await _pumpDetail(tester, _withdrawal(WithdrawalStatus.approved));

    expect(find.text('Đánh dấu đã thanh toán'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);
    expect(find.text('Phê duyệt'), findsNothing);
  });

  testWidgets('a processing withdrawal exposes only the payout refresh', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _withdrawal(WithdrawalStatus.processing, payoutId: 'PO-1'),
    );

    // Money is in flight at PayOS: nothing that moves it may be offered.
    expect(find.text('Cập nhật trạng thái thanh toán'), findsOneWidget);
    expect(find.text('Phê duyệt'), findsNothing);
    expect(find.text('Từ chối'), findsNothing);
    expect(find.text('Đánh dấu đã thanh toán'), findsNothing);
  });

  testWidgets('a failed withdrawal can be retried', (tester) async {
    final api = await _pumpDetail(
      tester,
      _withdrawal(WithdrawalStatus.failed, payoutId: 'PO-1'),
    );

    expect(find.text('Thử thanh toán lại'), findsOneWidget);
    expect(find.text('Phê duyệt'), findsNothing);

    await tester.tap(find.text('Thử thanh toán lại'));
    await tester.pumpAndSettle();

    // Irreversible money movement is confirmed first.
    expect(find.text('Hủy'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(api.retryCalls, 1);
  });

  testWidgets('a paid withdrawal offers no money-moving action at all', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _withdrawal(WithdrawalStatus.paid, payoutId: 'PO-1'),
    );

    expect(find.text('Đã thanh toán'), findsOneWidget);
    expect(find.text('Phê duyệt'), findsNothing);
    expect(find.text('Từ chối'), findsNothing);
    expect(find.text('Đánh dấu đã thanh toán'), findsNothing);
    expect(find.text('Thử thanh toán lại'), findsNothing);
    // The receipt stays reachable from the app bar.
    expect(find.byTooltip('Xem biên nhận'), findsOneWidget);
  });

  testWidgets('approving a withdrawal is confirmed before it fires', (
    tester,
  ) async {
    final api = await _pumpDetail(
      tester,
      _withdrawal(WithdrawalStatus.pending),
    );

    await tester.tap(find.text('Phê duyệt'));
    await tester.pumpAndSettle();

    expect(find.text('Duyệt yêu cầu rút tiền'), findsOneWidget);
    expect(find.textContaining('không thể hoàn tác'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();
    expect(api.approveCalls, 0);

    await tester.tap(find.text('Phê duyệt'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Phê duyệt'));
    await tester.pumpAndSettle();
    expect(api.approveCalls, 1);
  });
}
