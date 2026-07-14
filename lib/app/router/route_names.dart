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
  static const coaches = '/coaches';
  static const schedule = '/schedule';
  static const messages = '/messages';
  static const account = '/account';

  // Public coach directory (`coaches` above is the tab it lives in)
  static const coachDetail = '/coaches/:id';
  static String coachDetailPath(String id) => '/coaches/$id';

  // Packages — full-screen, opened from the home shortcut or a coach profile
  static const packages = '/packages';
  static const packageDetail = '/packages/:id';
  static String packageDetailPath(String id) => '/packages/$id';

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

  // ───────────────────────────── Admin ─────────────────────────────
  // Admin shell tabs (own indexed stack, separate from the learner/coach shell)
  static const adminDashboard = '/admin/dashboard';
  static const adminApprovals = '/admin/approvals';
  static const adminFinance = '/admin/finance';
  static const adminUsers = '/admin/users';
  static const adminMore = '/admin/more';

  /// Any location inside the admin area (used by the router guard).
  static bool isAdminLocation(String location) => location.startsWith('/admin');

  // Users
  static const adminUserCreate = '/admin/users/new';
  static const adminUserDetail = '/admin/users/:id';
  static String adminUserDetailPath(String id) => '/admin/users/$id';
  static const adminUserEdit = '/admin/users/:id/edit';
  static String adminUserEditPath(String id) => '/admin/users/$id/edit';

  // Moderation details
  static const adminPackageDetail = '/admin/training-packages/:id';
  static String adminPackageDetailPath(String id) =>
      '/admin/training-packages/$id';
  static const adminPostDetail = '/admin/posts/:id';
  static String adminPostDetailPath(String id) => '/admin/posts/$id';
  static const adminReviewReportDetail = '/admin/review-reports/:id';
  static String adminReviewReportDetailPath(String id) =>
      '/admin/review-reports/$id';
  static const adminPayoutAccountDetail = '/admin/payout-accounts/:id';
  static String adminPayoutAccountDetailPath(String id) =>
      '/admin/payout-accounts/$id';

  // Withdrawals
  static const adminWithdrawalDetail = '/admin/withdrawals/:id';
  static String adminWithdrawalDetailPath(String id) =>
      '/admin/withdrawals/$id';
  static const adminWithdrawalReceipt = '/admin/withdrawals/:id/receipt';
  static String adminWithdrawalReceiptPath(String id) =>
      '/admin/withdrawals/$id/receipt';

  // Platform settings
  static const adminCommission = '/admin/settings/commission';
}
