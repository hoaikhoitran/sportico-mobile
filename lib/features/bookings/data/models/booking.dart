import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// `Booking.Status` — safe parse, unknown values never crash.
enum BookingStatus {
  pendingPayment,
  active,
  completed,
  cancelled,
  refunded,
  unknown;

  static BookingStatus parse(String? raw) => switch (raw) {
    'pending_payment' => pendingPayment,
    'active' => active,
    'completed' => completed,
    'cancelled' => cancelled,
    'refunded' => refunded,
    _ => unknown,
  };

  String get label => switch (this) {
    pendingPayment => 'Chờ thanh toán',
    active => 'Đang hoạt động',
    completed => 'Hoàn thành',
    cancelled => 'Đã hủy',
    refunded => 'Đã hoàn tiền',
    unknown => 'Không xác định',
  };
}

/// `BookingResponse` (docs/api/bookings.md).
class Booking {
  const Booking({
    required this.id,
    required this.learnerId,
    required this.coachId,
    required this.trainingPackageId,
    required this.trainingPackageTitle,
    required this.totalAmount,
    this.platformFeeRate = 0,
    this.platformFeeAmount = 0,
    this.coachReceiveAmount = 0,
    this.perSessionCoachAmount = 0,
    required this.totalSessions,
    required this.completedSessions,
    this.status = BookingStatus.unknown,
    this.paidAt,
    this.completedAt,
    this.cancelledAt,
    this.expiresAt,
    this.createdAt,
  });

  final String id;
  final String learnerId;
  final String coachId;
  final String trainingPackageId;
  final String trainingPackageTitle;
  final num totalAmount;
  final num platformFeeRate;
  final num platformFeeAmount;
  final num coachReceiveAmount;
  final num perSessionCoachAmount;
  final int totalSessions;
  final int completedSessions;
  final BookingStatus status;
  final DateTime? paidAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  String get totalAmountLabel => CurrencyFormatter.vnd(totalAmount);

  double get progress =>
      totalSessions == 0 ? 0 : completedSessions / totalSessions;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      learnerId: json['learnerId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      trainingPackageId: json['trainingPackageId'] as String? ?? '',
      trainingPackageTitle: json['trainingPackageTitle'] as String? ?? '',
      totalAmount: CurrencyFormatter.parseAmount(json['totalAmount']),
      platformFeeRate: CurrencyFormatter.parseAmount(json['platformFeeRate']),
      platformFeeAmount: CurrencyFormatter.parseAmount(
        json['platformFeeAmount'],
      ),
      coachReceiveAmount: CurrencyFormatter.parseAmount(
        json['coachReceiveAmount'],
      ),
      perSessionCoachAmount: CurrencyFormatter.parseAmount(
        json['perSessionCoachAmount'],
      ),
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      completedSessions: (json['completedSessions'] as num?)?.toInt() ?? 0,
      status: BookingStatus.parse(json['status'] as String?),
      paidAt: DateFormatter.parseUtc(json['paidAt'] as String?),
      completedAt: DateFormatter.parseUtc(json['completedAt'] as String?),
      cancelledAt: DateFormatter.parseUtc(json['cancelledAt'] as String?),
      expiresAt: DateFormatter.parseUtc(json['expiresAt'] as String?),
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
    );
  }
}
