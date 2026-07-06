/// Central route table. Paths are the single source of truth for go_router.
abstract final class RouteNames {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';

  // Shell tabs
  static const home = '/home';
  static const packages = '/packages';
  static const schedule = '/schedule';
  static const messages = '/messages';
  static const account = '/account';

  // Packages
  static const packageDetail = '/packages/:id';
  static String packageDetailPath(String id) => '/packages/$id';

  // Public coach directory
  static const coaches = '/coaches';
  static const coachDetail = '/coaches/:id';
  static String coachDetailPath(String id) => '/coaches/$id';

  // Bookings (learner + coach share the detail screen)
  static const bookings = '/bookings';
  static const bookingDetail = '/bookings/:id';
  static String bookingDetailPath(String id) => '/bookings/$id';
  static const coachBookings = '/coach/bookings';
  static const coachBookingDetail = '/coach/bookings/:id';
  static String coachBookingDetailPath(String id) => '/coach/bookings/$id';

  // Personalized training (scoped to a booking). `?as=coach` tells the
  // screen which side of the booking the viewer is on — needed because a
  // user can hold both roles at once.
  static const assessment = '/bookings/:id/assessment';
  static String assessmentPath(String bookingId, {bool asCoach = false}) =>
      '/bookings/$bookingId/assessment${asCoach ? '?as=coach' : ''}';
  static const trainingPlan = '/bookings/:id/plan';
  static String trainingPlanPath(String bookingId, {bool asCoach = false}) =>
      '/bookings/$bookingId/plan${asCoach ? '?as=coach' : ''}';
  static const progressCheckIns = '/bookings/:id/check-ins';
  static String progressCheckInsPath(
    String bookingId, {
    bool asCoach = false,
  }) => '/bookings/$bookingId/check-ins${asCoach ? '?as=coach' : ''}';

  // Coach area
  static const coachOnboarding = '/coach/onboarding';
  static const coachPackages = '/coach/packages';
  static const coachPackageCreate = '/coach/packages/new';
  static const coachPackageEdit = '/coach/packages/:id/edit';
  static String coachPackageEditPath(String id) => '/coach/packages/$id/edit';
  static const coachWallet = '/coach/wallet';
  static const withdrawalComingSoon = '/coach/wallet/withdrawal';

  // Chat
  static const chatDetail = '/messages/:roomId';
  static String chatDetailPath(String roomId) => '/messages/$roomId';

  // Notifications
  static const notifications = '/notifications';

  // Admin accounts get an "unsupported on mobile" screen in phase 1
  static const adminUnsupported = '/admin-unsupported';
}
