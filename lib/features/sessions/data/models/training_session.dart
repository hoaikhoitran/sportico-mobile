import '../../../../core/utils/date_formatter.dart';

/// `TrainingSession.Status` — safe parse.
enum SessionStatus {
  requested,
  scheduled,
  completed,
  cancelled,
  missed,
  unknown;

  static SessionStatus parse(String? raw) => switch (raw) {
    'requested' => requested,
    'scheduled' => scheduled,
    'completed' => completed,
    'cancelled' => cancelled,
    'missed' => missed,
    _ => unknown,
  };

  String get label => switch (this) {
    requested => 'Chờ xác nhận',
    scheduled => 'Đã xếp lịch',
    completed => 'Hoàn thành',
    cancelled => 'Đã hủy',
    missed => 'Vắng mặt',
    unknown => 'Không xác định',
  };
}

/// `TrainingSessionResponse` (docs/api/training-sessions.md).
class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.bookingId,
    required this.learnerId,
    required this.coachId,
    this.startTime,
    this.endTime,
    this.status = SessionStatus.unknown,
    this.meetingUrl,
    this.location,
    this.learnerNote,
    this.coachNote,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
  });

  final String id;
  final String bookingId;
  final String learnerId;
  final String coachId;
  final DateTime? startTime;
  final DateTime? endTime;
  final SessionStatus status;
  final String? meetingUrl;
  final String? location;
  final String? learnerNote;
  final String? coachNote;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  bool get isUpcoming =>
      startTime != null && startTime!.isAfter(DateTime.now());

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      learnerId: json['learnerId'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      startTime: DateFormatter.parseUtc(json['startTime'] as String?),
      endTime: DateFormatter.parseUtc(json['endTime'] as String?),
      status: SessionStatus.parse(json['status'] as String?),
      meetingUrl: json['meetingUrl'] as String?,
      location: json['location'] as String?,
      learnerNote: json['learnerNote'] as String?,
      coachNote: json['coachNote'] as String?,
      confirmedAt: DateFormatter.parseUtc(json['confirmedAt'] as String?),
      completedAt: DateFormatter.parseUtc(json['completedAt'] as String?),
      cancelledAt: DateFormatter.parseUtc(json['cancelledAt'] as String?),
    );
  }
}
