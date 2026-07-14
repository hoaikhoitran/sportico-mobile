import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:group_prj/core/network/api_result.dart';
import 'package:group_prj/features/admin/settings/data/admin_settings_api.dart';
import 'package:group_prj/features/admin/settings/data/models/platform_commission.dart';
import 'package:group_prj/features/admin/settings/presentation/admin_commission_screen.dart';

class _FakeSettingsApi extends AdminSettingsApi {
  _FakeSettingsApi() : super(Dio());

  num percent = 15;
  final List<num> updates = [];

  @override
  Future<ApiResult<PlatformCommission>> commission() async =>
      ApiSuccess(PlatformCommission(commissionPercent: percent));

  @override
  Future<ApiResult<PlatformCommission>> updateCommission(
    num commissionPercent,
  ) async {
    updates.add(commissionPercent);
    percent = commissionPercent;
    return ApiSuccess(PlatformCommission(commissionPercent: commissionPercent));
  }
}

Future<_FakeSettingsApi> _pump(WidgetTester tester) async {
  final api = _FakeSettingsApi();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [adminSettingsApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: AdminCommissionScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('shows the current rate as a percent and warns about scope', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('15%'), findsOneWidget);
    // The admin must know the change is not retroactive.
    expect(find.textContaining('không bị tính lại'), findsOneWidget);
  });

  testWidgets('save stays disabled until something actually changes', (
    tester,
  ) async {
    await _pump(tester);

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Lưu thay đổi'),
    );

    expect(saveButton().onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), '18');
    await tester.pump();

    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets('an out-of-range rate is rejected before any request', (
    tester,
  ) async {
    final api = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), '120');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(find.text('Tỷ lệ hoa hồng phải từ 0 đến 100.'), findsOneWidget);
    expect(api.updates, isEmpty);
  });

  testWidgets('saving confirms first, then sends a percent value', (
    tester,
  ) async {
    final api = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), '18');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(find.text('Cập nhật hoa hồng'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cập nhật'));
    await tester.pumpAndSettle();

    // 18 percent — not 0.18: the backend divides by 100 itself.
    expect(api.updates, [18]);
    expect(find.text('Đã cập nhật tỷ lệ hoa hồng.'), findsOneWidget);
    expect(find.text('18%'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation sends nothing', (tester) async {
    final api = await _pump(tester);

    await tester.enterText(find.byType(TextFormField), '18');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu thay đổi'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();

    expect(api.updates, isEmpty);
  });
}
