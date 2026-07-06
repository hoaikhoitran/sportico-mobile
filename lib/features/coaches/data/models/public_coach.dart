import '../../../../core/utils/currency_formatter.dart';

/// One row of `GET /api/public/coaches`.
class PublicCoach {
  const PublicCoach({
    required this.coachId,
    required this.fullName,
    this.avatarUrl,
    this.headline,
    this.bio,
    this.experienceYears,
    this.coverImageUrl,
    this.teachingCity,
    this.teachingDistrict,
    this.isOnlineAvailable = false,
    this.isOfflineAvailable = false,
    this.specialties,
    this.rating = 0,
    this.totalReviews = 0,
    this.sports = const [],
  });

  final String coachId;
  final String fullName;
  final String? avatarUrl;
  final String? headline;
  final String? bio;
  final int? experienceYears;
  final String? coverImageUrl;
  final String? teachingCity;
  final String? teachingDistrict;
  final bool isOnlineAvailable;
  final bool isOfflineAvailable;
  final String? specialties;
  final num rating;
  final int totalReviews;
  final List<CoachSport> sports;

  factory PublicCoach.fromJson(Map<String, dynamic> json) => PublicCoach(
    coachId: json['coachId'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    headline: json['headline'] as String?,
    bio: json['bio'] as String?,
    experienceYears: (json['experienceYears'] as num?)?.toInt(),
    coverImageUrl: json['coverImageUrl'] as String?,
    teachingCity: json['teachingCity'] as String?,
    teachingDistrict: json['teachingDistrict'] as String?,
    isOnlineAvailable: json['isOnlineAvailable'] as bool? ?? false,
    isOfflineAvailable: json['isOfflineAvailable'] as bool? ?? false,
    specialties: json['specialties'] as String?,
    rating: json['rating'] as num? ?? 0,
    totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    sports: (json['sports'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CoachSport.fromJson)
        .toList(),
  );

  /// "Phường Long Bình, Thành phố Hồ Chí Minh" (parts that exist).
  String? get locationLabel {
    final parts = [
      ?teachingDistrict,
      ?teachingCity,
    ].where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

class CoachSport {
  const CoachSport({required this.id, required this.name});

  final int id;
  final String name;

  factory CoachSport.fromJson(Map<String, dynamic> json) => CoachSport(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
  );
}

/// `GET /api/public/coaches/{coachId}` — profile plus published packages
/// and gallery/certificate media.
class PublicCoachDetail extends PublicCoach {
  const PublicCoachDetail({
    required super.coachId,
    required super.fullName,
    super.avatarUrl,
    super.headline,
    super.bio,
    super.experienceYears,
    super.coverImageUrl,
    super.teachingCity,
    super.teachingDistrict,
    super.isOnlineAvailable,
    super.isOfflineAvailable,
    super.specialties,
    super.rating,
    super.totalReviews,
    super.sports,
    this.teachingAddress,
    this.certificationsSummary,
    this.achievementsSummary,
    this.trainingPackages = const [],
  });

  final String? teachingAddress;
  final String? certificationsSummary;
  final String? achievementsSummary;
  final List<CoachPackageItem> trainingPackages;

  factory PublicCoachDetail.fromJson(Map<String, dynamic> json) {
    final base = PublicCoach.fromJson(json);
    return PublicCoachDetail(
      coachId: base.coachId,
      fullName: base.fullName,
      avatarUrl: base.avatarUrl,
      headline: base.headline,
      bio: base.bio,
      experienceYears: base.experienceYears,
      coverImageUrl: base.coverImageUrl,
      teachingCity: base.teachingCity,
      teachingDistrict: base.teachingDistrict,
      isOnlineAvailable: base.isOnlineAvailable,
      isOfflineAvailable: base.isOfflineAvailable,
      specialties: base.specialties,
      rating: base.rating,
      totalReviews: base.totalReviews,
      sports: base.sports,
      teachingAddress: json['teachingAddress'] as String?,
      certificationsSummary: json['certificationsSummary'] as String?,
      achievementsSummary: json['achievementsSummary'] as String?,
      trainingPackages: (json['trainingPackages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CoachPackageItem.fromJson)
          .toList(),
    );
  }
}

/// Package summary embedded in the public coach profile.
class CoachPackageItem {
  const CoachPackageItem({
    required this.id,
    required this.title,
    required this.sportName,
    required this.price,
    required this.sessionCount,
    this.isOnline = false,
    this.location,
    this.status = '',
  });

  final String id;
  final String title;
  final String sportName;
  final num price;
  final int sessionCount;
  final bool isOnline;
  final String? location;
  final String status;

  String get priceLabel => CurrencyFormatter.vnd(price);

  factory CoachPackageItem.fromJson(Map<String, dynamic> json) =>
      CoachPackageItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        sportName: json['sportName'] as String? ?? '',
        price: CurrencyFormatter.parseAmount(json['price']),
        sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
        isOnline: json['isOnline'] as bool? ?? false,
        location: json['location'] as String?,
        status: json['status'] as String? ?? '',
      );
}

/// `ReviewResponse` from the coach reviews endpoints.
class CoachReview {
  const CoachReview({
    required this.id,
    required this.learnerId,
    required this.learnerName,
    this.learnerAvatarUrl,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String learnerId;
  final String learnerName;
  final String? learnerAvatarUrl;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory CoachReview.fromJson(Map<String, dynamic> json) => CoachReview(
    id: json['id'] as String? ?? '',
    learnerId: json['learnerId'] as String? ?? '',
    learnerName: json['learnerName'] as String? ?? 'Người tập',
    learnerAvatarUrl: json['learnerAvatarUrl'] as String?,
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    comment: json['comment'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
}

/// `GET /api/coaches/{coachId}/reviews/summary`.
class CoachReviewSummary {
  const CoachReviewSummary({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.breakdown = const [0, 0, 0, 0, 0],
  });

  final num averageRating;
  final int totalReviews;

  /// Counts for 1★..5★ (index 0 = 1 star).
  final List<int> breakdown;

  factory CoachReviewSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['ratingBreakdown'];
    final map = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    int count(String key) => (map[key] as num?)?.toInt() ?? 0;
    return CoachReviewSummary(
      averageRating: json['averageRating'] as num? ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      breakdown: [
        count('oneStar'),
        count('twoStar'),
        count('threeStar'),
        count('fourStar'),
        count('fiveStar'),
      ],
    );
  }
}
