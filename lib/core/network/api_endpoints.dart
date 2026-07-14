/// Every backend route used by the app — phase-1 allow-list only.
///
/// Legacy modules (`/api/packages`, `/api/coach-packages`, `/api/posts`),
/// PayOS purchase, and withdrawal-request endpoints are intentionally absent.
abstract final class ApiEndpoints {
  // Auth
  static const register = '/api/auth/register';
  static const verifyEmail = '/api/auth/verify-email';
  static const resendVerificationEmail = '/api/auth/resend-verification-email';
  static const login = '/api/auth/login';
  static const refreshToken = '/api/auth/refresh-token';
  static const forgotPassword = '/api/auth/forgot-password';
  static const resetPassword = '/api/auth/reset-password';
  static const changePassword = '/api/auth/change-password';
  static const coachRegister = '/api/coaches/register';

  // Current user profile (documented in docs/api/users.md)
  static const me = '/api/users/me';

  // Public coach directory
  static const publicCoaches = '/api/public/coaches';
  static String publicCoach(String coachId) => '/api/public/coaches/$coachId';

  // Coach reviews
  static String coachReviews(String coachId) => '/api/coaches/$coachId/reviews';
  static String coachReviewSummary(String coachId) =>
      '/api/coaches/$coachId/reviews/summary';

  // Training packages
  static const publicPackages = '/api/public/training-packages';
  static String publicPackage(String id) => '/api/public/training-packages/$id';
  static const packages = '/api/training-packages';
  static const myPackages = '/api/training-packages/me';
  static String myPackage(String id) => '/api/training-packages/me/$id';
  static String package(String id) => '/api/training-packages/$id';
  static String archivePackage(String id) =>
      '/api/training-packages/$id/archive';

  // Bookings
  static const purchaseManual = '/api/bookings/purchase/manual';
  static const purchasePayOs = '/api/bookings/purchase/payos';
  static const myBookings = '/api/bookings/me';
  static String booking(String id) => '/api/bookings/$id';
  static const coachBookings = '/api/bookings/coach';
  static String coachBooking(String id) => '/api/bookings/coach/$id';

  // Training sessions
  static String bookingSessions(String bookingId) =>
      '/api/bookings/$bookingId/sessions';
  static const learnerSessions = '/api/learners/me/training-sessions';
  static const coachSessions = '/api/coaches/me/training-sessions';
  static String confirmSession(String id) =>
      '/api/training-sessions/$id/confirm';
  static String cancelSession(String id) => '/api/training-sessions/$id/cancel';
  static String completeSession(String id) =>
      '/api/training-sessions/$id/complete';

  // Personalized training
  static String assessment(String bookingId) =>
      '/api/bookings/$bookingId/assessment';
  static String trainingPlan(String bookingId) =>
      '/api/bookings/$bookingId/training-plan';
  static String updateTrainingPlan(String id) => '/api/training-plans/$id';
  static String planWeeks(String planId) => '/api/training-plans/$planId/weeks';
  static String weekDays(String weekId) =>
      '/api/training-plan-weeks/$weekId/days';
  static String dayExercises(String dayId) =>
      '/api/training-plan-days/$dayId/exercises';
  static String exercise(String id) => '/api/training-plan-exercises/$id';
  static String progressCheckIns(String bookingId) =>
      '/api/bookings/$bookingId/progress-checkins';
  static String checkInFeedback(String id) =>
      '/api/progress-checkins/$id/coach-feedback';

  // Chat
  static const chatRooms = '/api/chat/rooms';
  static String chatMessages(String roomId) =>
      '/api/chat/rooms/$roomId/messages';

  // Notifications
  static const notifications = '/api/notifications/me';
  static const unreadCount = '/api/notifications/me/unread-count';
  static String markNotificationRead(String id) =>
      '/api/notifications/$id/read';
  static const markAllNotificationsRead = '/api/notifications/me/read-all';

  // Coach wallet (read-only in phase 1)
  static const coachWallet = '/api/coaches/me/wallet';
  static const coachWalletTransactions = '/api/coaches/me/wallet/transactions';

  // Public user profile
  static String publicUser(String id) => '/api/users/$id';

  // ───────────────────────────── Admin ─────────────────────────────
  // Every route below is `[Authorize(Roles = "admin")]` on the backend.
  static const adminDashboard = '/api/admin/dashboard';

  static const adminUsers = '/api/admin/users';
  static String adminUser(String id) => '/api/admin/users/$id';

  static const adminPendingPackages = '/api/admin/training-packages/pending';
  static String adminApprovePackage(String id) =>
      '/api/admin/training-packages/$id/approve';
  static String adminRejectPackage(String id) =>
      '/api/admin/training-packages/$id/reject';

  static const adminPendingPosts = '/api/admin/posts/pending';
  static String adminApprovePost(String id) => '/api/admin/posts/$id/approve';
  static String adminRejectPost(String id) => '/api/admin/posts/$id/reject';

  static const adminReviewReports = '/api/admin/review-reports';
  static String adminResolveReviewReport(String id) =>
      '/api/admin/review-reports/$id/resolve';

  static const adminPendingPayoutAccounts =
      '/api/admin/coach-payout-accounts/pending';
  static String adminVerifyPayoutAccount(String id) =>
      '/api/admin/coach-payout-accounts/$id/verify';
  static String adminRejectPayoutAccount(String id) =>
      '/api/admin/coach-payout-accounts/$id/reject';

  static const adminWithdrawals = '/api/admin/withdrawal-requests';
  static const adminPendingWithdrawals =
      '/api/admin/withdrawal-requests/pending';
  static String adminWithdrawal(String id) =>
      '/api/admin/withdrawal-requests/$id';
  static String adminApproveWithdrawal(String id) =>
      '/api/admin/withdrawal-requests/$id/approve';
  static String adminRejectWithdrawal(String id) =>
      '/api/admin/withdrawal-requests/$id/reject';
  static String adminMarkWithdrawalPaid(String id) =>
      '/api/admin/withdrawal-requests/$id/mark-paid';
  static String adminRefreshPayoutStatus(String id) =>
      '/api/admin/withdrawal-requests/$id/refresh-payout-status';
  static String adminRetryPayout(String id) =>
      '/api/admin/withdrawal-requests/$id/retry-payout';
  static String adminWithdrawalReceipt(String id) =>
      '/api/admin/withdrawal-requests/$id/receipt';

  static const adminCommission = '/api/admin/platform-settings/commission';
}
