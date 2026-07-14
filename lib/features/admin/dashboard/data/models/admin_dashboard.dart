import '../../../../../core/utils/currency_formatter.dart';

/// `AdminDashboardResponse` from `GET /api/admin/dashboard`.
///
/// The DTO is a flat set of counters and money totals — there is **no**
/// time-series data in the contract, so the dashboard renders KPI cards and no
/// chart. Nothing here is derived or estimated on the client.
class AdminDashboard {
  const AdminDashboard({
    required this.totalUsers,
    required this.totalLearners,
    required this.totalCoaches,
    required this.publishedPackages,
    required this.totalBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.grossRevenue,
    required this.platformFeeRevenue,
    required this.coachPayable,
    required this.totalWithdrawnPaid,
    required this.pendingWithdrawals,
    required this.processingWithdrawals,
    required this.paidWithdrawals,
    required this.failedWithdrawals,
  });

  // Users
  final int totalUsers;
  final int totalLearners;
  final int totalCoaches;

  // Catalog
  final int publishedPackages;

  // Bookings
  final int totalBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;

  // Accounting (paid bookings only, per the backend DTO docs)
  final num grossRevenue;
  final num platformFeeRevenue;
  final num coachPayable;
  final num totalWithdrawnPaid;

  // Withdrawals by status
  final int pendingWithdrawals;
  final int processingWithdrawals;
  final int paidWithdrawals;
  final int failedWithdrawals;

  String get grossRevenueLabel => CurrencyFormatter.vnd(grossRevenue);
  String get platformFeeRevenueLabel =>
      CurrencyFormatter.vnd(platformFeeRevenue);
  String get coachPayableLabel => CurrencyFormatter.vnd(coachPayable);
  String get totalWithdrawnPaidLabel =>
      CurrencyFormatter.vnd(totalWithdrawnPaid);

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    return AdminDashboard(
      totalUsers: count('totalUsers'),
      totalLearners: count('totalLearners'),
      totalCoaches: count('totalCoaches'),
      publishedPackages: count('publishedPackages'),
      totalBookings: count('totalBookings'),
      activeBookings: count('activeBookings'),
      completedBookings: count('completedBookings'),
      cancelledBookings: count('cancelledBookings'),
      grossRevenue: CurrencyFormatter.parseAmount(json['grossRevenue']),
      platformFeeRevenue: CurrencyFormatter.parseAmount(
        json['platformFeeRevenue'],
      ),
      coachPayable: CurrencyFormatter.parseAmount(json['coachPayable']),
      totalWithdrawnPaid: CurrencyFormatter.parseAmount(
        json['totalWithdrawnPaid'],
      ),
      pendingWithdrawals: count('pendingWithdrawals'),
      processingWithdrawals: count('processingWithdrawals'),
      paidWithdrawals: count('paidWithdrawals'),
      failedWithdrawals: count('failedWithdrawals'),
    );
  }
}

/// `DashboardFilterRequest` — the only two filters the endpoint supports.
///
/// The backend bounds bookings/payments by `CreatedAt` and withdrawals by
/// `CreatedAt`; wallet balances are a point-in-time snapshot and ignore the
/// range.
class DashboardFilter {
  const DashboardFilter({
    this.fromDate,
    this.toDate,
    this.label = 'Toàn thời gian',
  });

  final DateTime? fromDate;
  final DateTime? toDate;

  /// Vietnamese description of the active period, shown under the title.
  final String label;

  static const allTime = DashboardFilter();

  static DashboardFilter lastDays(int days, String label) {
    final now = DateTime.now();
    return DashboardFilter(
      fromDate: DateTime(now.year, now.month, now.day - (days - 1)),
      toDate: now,
      label: label,
    );
  }

  static DashboardFilter range(DateTime from, DateTime to, String label) =>
      DashboardFilter(fromDate: from, toDate: to, label: label);

  bool get isAllTime => fromDate == null && toDate == null;

  Map<String, dynamic> toQuery() => {
    'FromDate': ?fromDate?.toUtc().toIso8601String(),
    'ToDate': ?toDate?.toUtc().toIso8601String(),
  };
}
