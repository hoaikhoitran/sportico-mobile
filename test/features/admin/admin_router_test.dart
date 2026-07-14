import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:group_prj/app/router/app_router.dart';
import 'package:group_prj/app/router/route_names.dart';
import 'package:group_prj/core/network/dio_client.dart';
import 'package:group_prj/features/admin/dashboard/data/admin_dashboard_api.dart';
import 'package:group_prj/features/admin/dashboard/presentation/admin_dashboard_screen.dart';
import 'package:group_prj/features/admin/users/presentation/admin_users_screen.dart';
import 'package:group_prj/features/auth/data/models/current_user.dart';
import 'package:group_prj/features/auth/presentation/auth_controller.dart';
import 'package:group_prj/features/home/presentation/home_screen.dart';

import 'support/fake_admin_apis.dart';

/// Auth stub: the router only reads roles + status from here.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;
}

AuthState _authenticated(List<String> roles) => AuthState(
  status: AuthStatus.authenticated,
  user: CurrentUser(
    id: 'u-1',
    email: 'user@sportico.vn',
    fullName: 'Người dùng',
    roles: roles,
  ),
  roles: roles,
);

/// Dio that never reaches the network: the learner/coach screens we may land on
/// must not fire real requests during the test.
Dio _offlineDio() {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:1'));
  dio.httpClientAdapter = _DeadAdapter();
  return dio;
}

class _DeadAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline test',
    );
  }
}

Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required List<String> roles,
  String? initialLocation,
}) async {
  final container = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(_offlineDio()),
      authControllerProvider.overrideWith(
        () => _FakeAuthController(_authenticated(roles)),
      ),
      adminDashboardApiProvider.overrideWithValue(
        FakeAdminDashboardApi(dashboard: sampleDashboard()),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = container.read(appRouterProvider);
  if (initialLocation != null) router.go(initialLocation);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return router;
}

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  testWidgets('an admin-only account lands on the admin dashboard', (
    tester,
  ) async {
    final router = await _pumpApp(tester, roles: ['admin']);

    expect(_location(router), RouteNames.adminDashboard);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    // The obsolete "not supported on mobile" screen is gone: the admin now has
    // real content.
    expect(find.text('Tổng quan'), findsWidgets);
  });

  testWidgets('an admin-only account cannot leave the admin area', (
    tester,
  ) async {
    final router = await _pumpApp(tester, roles: ['admin']);

    router.go(RouteNames.home);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(_location(router), RouteNames.adminDashboard);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('a learner cannot open an admin route by deep link', (
    tester,
  ) async {
    final router = await _pumpApp(
      tester,
      roles: ['learner'],
      initialLocation: RouteNames.adminUsers,
    );

    // Redirected out of the admin area — no admin screen is ever built.
    expect(_location(router), RouteNames.home);
    expect(find.byType(AdminUsersScreen), findsNothing);
    expect(find.byType(AdminDashboardScreen), findsNothing);
  });

  testWidgets('a coach cannot open the admin dashboard', (tester) async {
    final router = await _pumpApp(
      tester,
      roles: ['coach'],
      initialLocation: RouteNames.adminDashboard,
    );

    expect(_location(router), RouteNames.home);
    expect(find.byType(AdminDashboardScreen), findsNothing);
  });

  testWidgets('a learner keeps the normal app as its home', (tester) async {
    final router = await _pumpApp(tester, roles: ['learner']);

    expect(_location(router), RouteNames.home);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('an account with admin + learner roles starts in the user app '
      'but may enter the admin area', (tester) async {
    final router = await _pumpApp(tester, roles: ['admin', 'learner']);

    // Multi-role accounts must not lose their learner experience.
    expect(_location(router), RouteNames.home);

    router.go(RouteNames.adminDashboard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(_location(router), RouteNames.adminDashboard);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
  });
}
