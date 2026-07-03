import '../../../../core/utils/date_formatter.dart';

/// `TrainingPlan.Status`: draft | active | completed | cancelled.
enum PlanStatus {
  draft,
  active,
  completed,
  cancelled,
  unknown;

  static PlanStatus parse(String? raw) => switch (raw) {
    'draft' => draft,
    'active' => active,
    'completed' => completed,
    'cancelled' => cancelled,
    _ => unknown,
  };

  String get label => switch (this) {
    draft => 'Bản nháp',
    active => 'Đang áp dụng',
    completed => 'Hoàn thành',
    cancelled => 'Đã hủy',
    unknown => 'Không xác định',
  };

  /// Allowed status transitions (mirrors backend rules).
  List<PlanStatus> get nextStatuses => switch (this) {
    draft => const [active, cancelled],
    active => const [completed, cancelled],
    _ => const [],
  };
}

/// `TrainingPlanResponse` with nested weeks → days → exercises.
class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.goalType,
    this.overview,
    this.startDate,
    this.endDate,
    this.totalWeeks = 0,
    this.status = PlanStatus.unknown,
    this.bookingExpiresAt,
    this.isReadOnly = false,
    this.readOnlyReason,
    this.weeks = const [],
  });

  final String id;
  final String bookingId;
  final String title;
  final String goalType;
  final String? overview;
  final DateTime? startDate;
  final DateTime? endDate;
  final int totalWeeks;
  final PlanStatus status;
  final DateTime? bookingExpiresAt;

  /// True when terminal status or the package expired — all mutations are
  /// blocked server-side; the UI hides edit controls.
  final bool isReadOnly;
  final String? readOnlyReason;
  final List<PlanWeek> weeks;

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      goalType: json['goalType'] as String? ?? '',
      overview: json['overview'] as String?,
      startDate: DateFormatter.parseUtc(json['startDate'] as String?),
      endDate: DateFormatter.parseUtc(json['endDate'] as String?),
      totalWeeks: (json['totalWeeks'] as num?)?.toInt() ?? 0,
      status: PlanStatus.parse(json['status'] as String?),
      bookingExpiresAt: DateFormatter.parseUtc(
        json['bookingExpiresAt'] as String?,
      ),
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      readOnlyReason: json['readOnlyReason'] as String?,
      weeks:
          (json['weeks'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PlanWeek.fromJson)
              .toList()
            ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber)),
    );
  }
}

class PlanWeek {
  const PlanWeek({
    required this.id,
    required this.weekNumber,
    this.focus,
    this.notes,
    this.days = const [],
  });

  final String id;
  final int weekNumber;
  final String? focus;
  final String? notes;
  final List<PlanDay> days;

  factory PlanWeek.fromJson(Map<String, dynamic> json) {
    return PlanWeek(
      id: json['id'] as String? ?? '',
      weekNumber: (json['weekNumber'] as num?)?.toInt() ?? 0,
      focus: json['focus'] as String?,
      notes: json['notes'] as String?,
      days:
          (json['days'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PlanDay.fromJson)
              .toList()
            ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber)),
    );
  }
}

class PlanDay {
  const PlanDay({
    required this.id,
    required this.dayNumber,
    required this.title,
    this.notes,
    this.exercises = const [],
  });

  final String id;
  final int dayNumber;
  final String title;
  final String? notes;
  final List<PlanExercise> exercises;

  factory PlanDay.fromJson(Map<String, dynamic> json) {
    return PlanDay(
      id: json['id'] as String? ?? '',
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      notes: json['notes'] as String?,
      exercises:
          (json['exercises'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(PlanExercise.fromJson)
              .toList()
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
    );
  }
}

class PlanExercise {
  const PlanExercise({
    required this.id,
    required this.exerciseName,
    this.orderIndex = 0,
    this.sets,
    this.reps,
    this.intensity,
    this.restSeconds,
    this.notes,
  });

  final String id;
  final String exerciseName;
  final int orderIndex;
  final int? sets;
  final String? reps;
  final String? intensity;
  final int? restSeconds;
  final String? notes;

  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      id: json['id'] as String? ?? '',
      exerciseName: json['exerciseName'] as String? ?? '',
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      sets: (json['sets'] as num?)?.toInt(),
      reps: json['reps'] as String?,
      intensity: json['intensity'] as String?,
      restSeconds: (json['restSeconds'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );
  }
}
