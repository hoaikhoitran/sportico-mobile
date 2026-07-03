import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/bookings/presentation/booking_detail_screen.dart';
import '../../features/bookings/presentation/coach_bookings_screen.dart';
import '../../features/bookings/presentation/learner_bookings_screen.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/chat/presentation/chat_rooms_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/coach/presentation/coach_onboarding_screen.dart';
import '../../features/coach/presentation/coach_package_form_screen.dart';
import '../../features/coach/presentation/coach_packages_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/presentation/admin_unsupported_screen.dart';
import '../../features/sessions/presentation/schedule_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/training_packages/presentation/package_detail_screen.dart';
import '../../features/training_packages/presentation/package_list_screen.dart';
import '../../features/training_plan/presentation/assessment_screen.dart';
import '../../features/wallet/presentation/coach_wallet_screen.dart';
import '../../features/wallet/presentation/withdrawal_coming_soon_screen.dart';
import '../../features/training_plan/presentation/progress_checkins_screen.dart';
import '../../features/training_plan/presentation/training_plan_screen.dart';
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
                builder: (context, state) => const PackageListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.schedule,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.messages,
                builder: (context, state) => const ChatRoomsScreen(),
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
            PackageDetailScreen(packageId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.bookings,
        builder: (context, state) => const LearnerBookingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.bookingDetail,
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['id']!,
          asCoach: false,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachBookingDetail,
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['id']!,
          asCoach: true,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.assessment,
        builder: (context, state) => AssessmentScreen(
          bookingId: state.pathParameters['id']!,
          asCoach: state.uri.queryParameters['as'] == 'coach',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.trainingPlan,
        builder: (context, state) => TrainingPlanScreen(
          bookingId: state.pathParameters['id']!,
          asCoach: state.uri.queryParameters['as'] == 'coach',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.progressCheckIns,
        builder: (context, state) => ProgressCheckInsScreen(
          bookingId: state.pathParameters['id']!,
          asCoach: state.uri.queryParameters['as'] == 'coach',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.chatDetail,
        builder: (context, state) => ChatDetailScreen(
          roomId: state.pathParameters['roomId']!,
          title: state.extra as String?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachOnboarding,
        builder: (context, state) => const CoachOnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachPackages,
        builder: (context, state) => const CoachPackagesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachPackageCreate,
        builder: (context, state) => const CoachPackageFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachPackageEdit,
        builder: (context, state) =>
            CoachPackageFormScreen(packageId: state.pathParameters['id']),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachBookings,
        builder: (context, state) => const CoachBookingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachWallet,
        builder: (context, state) => const CoachWalletScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.withdrawalComingSoon,
        builder: (context, state) => const WithdrawalComingSoonScreen(),
      ),
    ],
  );
});
