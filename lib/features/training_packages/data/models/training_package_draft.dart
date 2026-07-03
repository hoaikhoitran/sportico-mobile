/// Create/Update request bodies (`CreateTrainingPackageRequest` /
/// `UpdateTrainingPackageRequest`). The full fixed schedule is required:
/// `sessions.length == sessionCount`, numbers unique covering
/// `1..sessionCount`, each within `[startDate, endDate]`, no overlaps,
/// offline slots need a location. Backend re-validates everything.
class TrainingPackageDraft {
  const TrainingPackageDraft({
    required this.sportId,
    required this.title,
    this.description,
    required this.price,
    required this.startDate,
    required this.endDate,
    this.location,
    required this.isOnline,
    this.level,
    this.goalType,
    required this.sessions,
  });

  final int sportId;
  final String title;
  final String? description;
  final num price;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final bool isOnline;
  final String? level;
  final String? goalType;
  final List<SessionSlotDraft> sessions;

  Map<String, dynamic> toJson() => {
    'sportId': sportId,
    'title': title,
    'description': description,
    'price': price,
    'sessionCount': sessions.length,
    'startDate': startDate.toUtc().toIso8601String(),
    'endDate': endDate.toUtc().toIso8601String(),
    'location': location,
    'isOnline': isOnline,
    'level': level,
    'goalType': goalType,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}

class SessionSlotDraft {
  const SessionSlotDraft({
    required this.sessionNumber,
    required this.startTime,
    required this.endTime,
    this.level,
    required this.maxParticipants,
    this.location,
    required this.isOnline,
    this.meetingUrl,
    this.note,
  });

  final int sessionNumber;
  final DateTime startTime;
  final DateTime endTime;
  final String? level;
  final int maxParticipants;
  final String? location;
  final bool isOnline;
  final String? meetingUrl;
  final String? note;

  Map<String, dynamic> toJson() => {
    'sessionNumber': sessionNumber,
    'startTime': startTime.toUtc().toIso8601String(),
    'endTime': endTime.toUtc().toIso8601String(),
    'level': level,
    'maxParticipants': maxParticipants,
    'location': location,
    'isOnline': isOnline,
    'meetingUrl': meetingUrl,
    'note': note,
  };
}
