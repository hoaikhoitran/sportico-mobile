import '../../../../core/utils/date_formatter.dart';

/// `ProgressCheckInResponse` (docs/api/personalized-training.md).
class ProgressCheckIn {
  const ProgressCheckIn({
    required this.id,
    required this.bookingId,
    this.checkInDate,
    this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
    this.energyLevel,
    this.sleepQuality,
    this.learnerNote,
    this.coachFeedback,
  });

  final String id;
  final String bookingId;
  final DateTime? checkInDate;
  final num? weightKg;
  final num? bodyFatPercent;
  final num? waistCm;
  final String? energyLevel;
  final String? sleepQuality;
  final String? learnerNote;
  final String? coachFeedback;

  factory ProgressCheckIn.fromJson(Map<String, dynamic> json) {
    return ProgressCheckIn(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      checkInDate: DateFormatter.parseUtc(json['checkInDate'] as String?),
      weightKg: json['weightKg'] as num?,
      bodyFatPercent: json['bodyFatPercent'] as num?,
      waistCm: json['waistCm'] as num?,
      energyLevel: json['energyLevel'] as String?,
      sleepQuality: json['sleepQuality'] as String?,
      learnerNote: json['learnerNote'] as String?,
      coachFeedback: json['coachFeedback'] as String?,
    );
  }
}
