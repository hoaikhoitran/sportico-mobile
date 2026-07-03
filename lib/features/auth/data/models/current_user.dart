/// `CurrentUserResponse` from `GET /api/users/me` (docs/api/users.md).
class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.status = '',
    this.roles = const [],
    this.coachProfile,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String status;
  final List<String> roles;
  final CoachProfileSummary? coachProfile;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final coach = json['coachProfile'];
    return CurrentUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      coachProfile: coach is Map<String, dynamic>
          ? CoachProfileSummary.fromJson(coach)
          : null,
    );
  }
}

class CoachProfileSummary {
  const CoachProfileSummary({
    this.headline,
    this.bio,
    this.experienceYears,
    this.rating = 0,
    this.totalReviews = 0,
  });

  final String? headline;
  final String? bio;
  final int? experienceYears;
  final num rating;
  final int totalReviews;

  factory CoachProfileSummary.fromJson(Map<String, dynamic> json) {
    return CoachProfileSummary(
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      experienceYears: (json['experienceYears'] as num?)?.toInt(),
      rating: json['rating'] as num? ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }
}
