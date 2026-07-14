import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

/// `TrainingPackage.Status` — unknown values fall back to [unknown] so new
/// backend states never crash the app.
enum PackageStatus {
  pending,
  published,
  rejected,
  archived,
  unknown;

  static PackageStatus parse(String? raw) => switch (raw) {
    'pending' => pending,
    'published' => published,
    'rejected' => rejected,
    'archived' => archived,
    _ => unknown,
  };

  String get label => switch (this) {
    pending => 'Chờ duyệt',
    published => 'Đang mở bán',
    rejected => 'Bị từ chối',
    archived => 'Đã lưu trữ',
    unknown => 'Không xác định',
  };
}

/// Session slot status: `open | full | cancelled`.
enum SlotStatus {
  open,
  full,
  cancelled,
  unknown;

  static SlotStatus parse(String? raw) => switch (raw) {
    'open' => open,
    'full' => full,
    'cancelled' => cancelled,
    _ => unknown,
  };
}

/// One fixed schedule slot of a package.
class PackageSessionSlot {
  const PackageSessionSlot({
    this.id,
    required this.sessionNumber,
    this.startTime,
    this.endTime,
    this.level,
    this.location,
    this.isOnline = false,
    this.meetingUrl,
    this.note,
    this.maxParticipants = 1,
    this.bookedParticipants = 0,
    this.remainingParticipants,
    this.status = SlotStatus.unknown,
  });

  final String? id;
  final int sessionNumber;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? level;
  final String? location;
  final bool isOnline;
  final String? meetingUrl;
  final String? note;
  final int maxParticipants;
  final int bookedParticipants;
  final int? remainingParticipants;
  final SlotStatus status;

  factory PackageSessionSlot.fromJson(Map<String, dynamic> json) {
    return PackageSessionSlot(
      id: json['id'] as String?,
      sessionNumber: (json['sessionNumber'] as num?)?.toInt() ?? 0,
      startTime: DateFormatter.parseUtc(json['startTime'] as String?),
      endTime: DateFormatter.parseUtc(json['endTime'] as String?),
      level: json['level'] as String?,
      location: json['location'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      meetingUrl: json['meetingUrl'] as String?,
      note: json['note'] as String?,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 1,
      bookedParticipants: (json['bookedParticipants'] as num?)?.toInt() ?? 0,
      remainingParticipants: (json['remainingParticipants'] as num?)?.toInt(),
      status: SlotStatus.parse(json['status'] as String?),
    );
  }
}

/// Embedded coach summary on public package responses.
class PackageCoachSummary {
  const PackageCoachSummary({
    required this.coachId,
    required this.fullName,
    this.avatarUrl,
    this.headline,
    this.experienceYears,
    this.rating = 0,
    this.totalReviews = 0,
  });

  final String coachId;
  final String fullName;
  final String? avatarUrl;
  final String? headline;
  final int? experienceYears;
  final num rating;
  final int totalReviews;

  factory PackageCoachSummary.fromJson(Map<String, dynamic> json) {
    return PackageCoachSummary(
      coachId: json['coachId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      headline: json['headline'] as String?,
      experienceYears: (json['experienceYears'] as num?)?.toInt(),
      rating: json['rating'] as num? ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `TrainingPackageResponse` / `PublicTrainingPackageResponse`.
class TrainingPackage {
  const TrainingPackage({
    required this.id,
    required this.coachId,
    required this.sportId,
    required this.sportName,
    required this.title,
    this.description,
    required this.price,
    required this.sessionCount,
    required this.durationDays,
    this.startDate,
    this.endDate,
    this.location,
    this.isOnline = false,
    this.level,
    this.goalType,
    this.status = PackageStatus.unknown,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.sessions = const [],
    this.coach,
  });

  final String id;
  final String coachId;
  final int sportId;
  final String sportName;
  final String title;
  final String? description;
  final num price;
  final int sessionCount;
  final int durationDays;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? location;
  final bool isOnline;
  final String? level;
  final String? goalType;
  final PackageStatus status;
  final String? rejectionReason;

  /// Submission / last-change timestamps — the admin moderation queue orders
  /// and dates its cards by these; the learner-facing screens ignore them.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<PackageSessionSlot> sessions;
  final PackageCoachSummary? coach;

  String get priceLabel => CurrencyFormatter.vnd(price);

  factory TrainingPackage.fromJson(Map<String, dynamic> json) {
    final coach = json['coach'];
    return TrainingPackage(
      id: json['id'] as String? ?? '',
      coachId: json['coachId'] as String? ?? '',
      sportId: (json['sportId'] as num?)?.toInt() ?? 0,
      sportName: json['sportName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      price: CurrencyFormatter.parseAmount(json['price']),
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      startDate: DateFormatter.parseUtc(json['startDate'] as String?),
      endDate: DateFormatter.parseUtc(json['endDate'] as String?),
      location: json['location'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      level: json['level'] as String?,
      goalType: json['goalType'] as String?,
      status: PackageStatus.parse(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
      updatedAt: DateFormatter.parseUtc(json['updatedAt'] as String?),
      sessions: (json['sessions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PackageSessionSlot.fromJson)
          .toList(),
      coach: coach is Map<String, dynamic>
          ? PackageCoachSummary.fromJson(coach)
          : null,
    );
  }
}

/// Human labels for backend level/goal enum strings; unknown values pass
/// through unchanged.
abstract final class PackageLabels {
  static String level(String? raw) => switch (raw) {
    'beginner' => 'Người mới',
    'intermediate' => 'Trung cấp',
    'advanced' => 'Nâng cao',
    null || '' => '—',
    _ => raw,
  };

  static String goal(String? raw) => switch (raw) {
    'muscle_gain' => 'Tăng cơ',
    'weight_loss' => 'Giảm cân',
    'endurance' => 'Sức bền',
    'general_fitness' => 'Thể lực chung',
    'skill_improvement' => 'Nâng cao kỹ năng',
    null || '' => '—',
    _ => raw,
  };
}
