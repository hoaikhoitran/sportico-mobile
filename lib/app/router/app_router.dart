import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/moderation/data/models/admin_post.dart';
import '../../features/admin/moderation/data/models/coach_payout_account.dart';
import '../../features/admin/moderation/data/models/review_report.dart';
import '../../features/admin/moderation/presentation/admin_approvals_screen.dart';
import '../../features/admin/moderation/presentation/admin_package_detail_screen.dart';
import '../../features/admin/moderation/presentation/admin_payout_account_detail_screen.dart';
import '../../features/admin/moderation/presentation/admin_post_detail_screen.dart';
import '../../features/admin/moderation/presentation/admin_review_report_detail_screen.dart';
import '../../features/admin/dashboard/presentation/admin_dashboard_screen.dart';
import '../../features/admin/settings/presentation/admin_commission_screen.dart';
import '../../features/admin/shell/presentation/admin_more_screen.dart';
import '../../features/admin/shell/presentation/admin_shell_screen.dart';
import '../../features/admin/users/presentation/admin_user_detail_screen.dart';
import '../../features/admin/users/presentation/admin_user_form_screen.dart';
import '../../features/admin/users/presentation/admin_users_screen.dart';
import '../../features/admin/withdrawals/presentation/admin_finance_screen.dart';
import '../../features/admin/withdrawals/presentation/admin_withdrawal_detail_screen.dart';
import '../../features/admin/withdrawals/presentation/admin_withdrawal_receipt_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/bookings/presentation/booking_detail_screen.dart';
import '../../features/bookings/presentation/coach_bookings_screen.dart';
import '../../features/bookings/presentation/learner_bookings_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/chat/presentation/chat_detail_screen.dart';
import '../../features/chat/presentation/chat_rooms_screen.dart';
import '../../features/coaches/presentation/coach_detail_screen.dart';
import '../../features/coaches/presentation/coach_list_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/coach/presentation/coach_onboarding_screen.dart';
import '../../features/coach/presentation/coach_package_form_screen.dart';
import '../../features/coach/presentation/coach_packages_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/sessions/presentation/schedule_screen.dart';
import '../../features/shell/presentation/main_shell_screen.dart';
import '../../features/training_packages/data/models/training_package.dart';
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
      location == RouteNames.forgotPassword ||
      location == RouteNames.packages ||
      location == RouteNames.coaches ||
      RegExp(r'^/packages/[^/]+$').hasMatch(location) ||
      RegExp(r'^/coaches/[^/]+$').hasMatch(location);
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
          final isAdminLocation = RouteNames.isAdminLocation(location);

          // Guard: the admin area is closed to everyone else. Hiding the
          // entry points is not enough — a manual/deep link lands here too.
          // Roles come from the refreshed `/users/me` profile (AuthState),
          // not from a locally decoded JWT alone.
          if (isAdminLocation && !auth.isAdmin) {
            return RouteNames.home;
          }

          // An admin-only account has no learner/coach experience to fall back
          // on, so every non-admin location sends it to the admin dashboard.
          if (auth.isAdminOnly && !isAdminLocation) {
            return RouteNames.adminDashboard;
          }

          // Entry points: an admin-only account starts in the admin area, an
          // account that also has a learner/coach role keeps its normal home
          // (and reaches the admin area from the profile screen).
          if (location == RouteNames.splash ||
              location == RouteNames.login ||
              location == RouteNames.register) {
            return auth.isAdminOnly
                ? RouteNames.adminDashboard
                : RouteNames.home;
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
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Admin shell: its own indexed stack, so admin tabs keep their list and
      // filter state independently of the learner/coach shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminDashboard,
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminApprovals,
                builder: (context, state) => const AdminApprovalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminFinance,
                builder: (context, state) => const AdminFinanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminUsers,
                builder: (context, state) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.adminMore,
                builder: (context, state) => const AdminMoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // Admin full-screen routes (cover the admin bottom navigation).
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminUserCreate,
        builder: (context, state) => const AdminUserFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminUserEdit,
        builder: (context, state) =>
            AdminUserFormScreen(userId: state.pathParameters['id']),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminUserDetail,
        builder: (context, state) =>
            AdminUserDetailScreen(userId: state.pathParameters['id']!),
      ),
      // The moderation queues hand the loaded entity over in `extra` — the
      // admin API has no GET-by-id for these three.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminPackageDetail,
        builder: (context, state) => AdminPackageDetailScreen(
          packageId: state.pathParameters['id']!,
          initial: state.extra as TrainingPackage?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminPostDetail,
        builder: (context, state) => AdminPostDetailScreen(
          postId: state.pathParameters['id']!,
          initial: state.extra as AdminPost?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminReviewReportDetail,
        builder: (context, state) => AdminReviewReportDetailScreen(
          reportId: state.pathParameters['id']!,
          initial: state.extra as ReviewReport?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminPayoutAccountDetail,
        builder: (context, state) => AdminPayoutAccountDetailScreen(
          accountId: state.pathParameters['id']!,
          initial: state.extra as CoachPayoutAccount?,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminWithdrawalReceipt,
        builder: (context, state) => AdminWithdrawalReceiptScreen(
          withdrawalId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminWithdrawalDetail,
        builder: (context, state) => AdminWithdrawalDetailScreen(
          withdrawalId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.adminCommission,
        builder: (context, state) => const AdminCommissionScreen(),
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
                path: RouteNames.coaches,
                builder: (context, state) => const CoachListScreen(),
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
      // The package catalog lost its tab to the coach directory; it is still
      // reachable from the home shortcut and from a coach profile.
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.packages,
        builder: (context, state) => const PackageListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.packageDetail,
        builder: (context, state) =>
            PackageDetailScreen(packageId: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: RouteNames.coachDetail,
        builder: (context, state) =>
            CoachDetailScreen(coachId: state.pathParameters['id']!),
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
