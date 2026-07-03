import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/admin_unsupported_screen.dart';
import '../../features/shell/presentation/coming_soon_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import 'route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Locations reachable without a session (auth + public catalog).
bool _isPublicLocation(String location) {
  return location == RouteNames.login ||
      location == RouteNames.register ||
      location == RouteNames.verifyEmail ||
      location == RouteNames.packages ||
      RegExp(r'^/packages/[^/]+$').hasMatch(location);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever auth state changes without rebuilding the
  // router itself (which would lose navigation state).
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      switch (auth.status) {
        case AuthStatus.restoring:
          return location == RouteNames.splash ? null : RouteNames.splash;

        case AuthStatus.unauthenticated:
          if (location == RouteNames.splash) return RouteNames.login;
          return _isPublicLocation(location) ? null : RouteNames.login;

        case AuthStatus.authenticated:
          if (auth.isAdminOnly) {
            return location == RouteNames.adminUnsupported
                ? null
                : RouteNames.adminUnsupported;
          }
          if (location == RouteNames.splash ||
              location == RouteNames.login ||
              location == RouteNames.register ||
              location == RouteNames.adminUnsupported) {
            return RouteNames.home;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyEmail,
        builder: (context, state) =>
            VerifyEmailScreen(email: state.extra as String?),
      ),
      GoRoute(
        path: RouteNames.adminUnsupported,
        builder: (context, state) => const AdminUnsupportedScreen(),
      ),

      // Authenticated shell: 5 tabs with independent navigation stacks.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.packages,
                builder: (context, state) =>
                    const ComingSoonScreen(title: 'Gói tập'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.schedule,
                builder: (context, state) =>
                    const ComingSoonScreen(title: 'Lịch tập'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.messages,
                builder: (context, state) =>
                    const ComingSoonScreen(title: 'Tin nhắn'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.account,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes (cover the bottom navigation).
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.packageDetail,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Chi tiết gói tập'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.bookings,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Đơn đăng ký'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.bookingDetail,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Chi tiết đơn'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.notifications,
        builder: (context, state) => const ComingSoonScreen(title: 'Thông báo'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachOnboarding,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Đăng ký HLV'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachPackages,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Gói tập của tôi'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachBookings,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Học viên đăng ký'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachWallet,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Ví của tôi'),
      ),
    ],
  );
});
