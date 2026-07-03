import '../../../../core/utils/date_formatter.dart';

/// `LearnerAssessmentResponse` (docs/api/personalized-training.md).
class LearnerAssessment {
  const LearnerAssessment({
    required this.id,
    required this.bookingId,
    required this.goalType,
    this.goalDescription,
    this.heightCm,
    this.weightKg,
    this.bodyFatPercent,
    this.currentLevel,
    this.healthNotes,
    this.injuryNotes,
    this.trainingHistory,
    this.availableDaysPerWeek,
    this.preferredSessionDurationMinutes,
    this.equipmentAvailable,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String goalType;
  final String? goalDescription;
  final num? heightCm;
  final num? weightKg;
  final num? bodyFatPercent;
  final String? currentLevel;
  final String? healthNotes;
  final String? injuryNotes;
  final String? trainingHistory;
  final String? availableDaysPerWeek;
  final int? preferredSessionDurationMinutes;
  final String? equipmentAvailable;
  final DateTime? updatedAt;

  factory LearnerAssessment.fromJson(Map<String, dynamic> json) {
    return LearnerAssessment(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      goalType: json['goalType'] as String? ?? '',
      goalDescription: json['goalDescription'] as String?,
      heightCm: json['heightCm'] as num?,
      weightKg: json['weightKg'] as num?,
      bodyFatPercent: json['bodyFatPercent'] as num?,
      currentLevel: json['currentLevel'] as String?,
      healthNotes: json['healthNotes'] as String?,
      injuryNotes: json['injuryNotes'] as String?,
      trainingHistory: json['trainingHistory'] as String?,
      availableDaysPerWeek: json['availableDaysPerWeek'] as String?,
      preferredSessionDurationMinutes:
          (json['preferredSessionDurationMinutes'] as num?)?.toInt(),
      equipmentAvailable: json['equipmentAvailable'] as String?,
      updatedAt: DateFormatter.parseUtc(json['updatedAt'] as String?),
    );
  }
}

/// `CreateLearnerAssessmentRequest` / `UpdateLearnerAssessmentRequest` —
/// only `goalType` is required.
class AssessmentDraft {
  const AssessmentDraft({
    required this.goalType,
    this.goalDescription,
    this.heightCm,
    this.weightKg,
    this.bodyFatPercent,
    this.currentLevel,
    this.healthNotes,
    this.injuryNotes,
    this.trainingHistory,
    this.availableDaysPerWeek,
    this.preferredSessionDurationMinutes,
    this.equipmentAvailable,
  });

  final String goalType;
  final String? goalDescription;
  final num? heightCm;
  final num? weightKg;
  final num? bodyFatPercent;
  final String? currentLevel;
  final String? healthNotes;
  final String? injuryNotes;
  final String? trainingHistory;
  final String? availableDaysPerWeek;
  final int? preferredSessionDurationMinutes;
  final String? equipmentAvailable;

  Map<String, dynamic> toJson() => {
    'goalType': goalType,
    'goalDescription': ?goalDescription,
    'heightCm': ?heightCm,
    'weightKg': ?weightKg,
    'bodyFatPercent': ?bodyFatPercent,
    'currentLevel': ?currentLevel,
    'healthNotes': ?healthNotes,
    'injuryNotes': ?injuryNotes,
    'trainingHistory': ?trainingHistory,
    'availableDaysPerWeek': ?availableDaysPerWeek,
    'preferredSessionDurationMinutes': ?preferredSessionDurationMinutes,
    'equipmentAvailable': ?equipmentAvailable,
  };
}
