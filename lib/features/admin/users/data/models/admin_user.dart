import '../../../../../core/utils/date_formatter.dart';
import '../../../shared/models/admin_status.dart';

/// `AdminUserResponse` — the shape returned by every `/api/admin/users` route.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.status = AdminUserStatus.unknown,
    this.roles = const [],
    this.createdAt,
    this.updatedAt,
    this.coachProfile,
    this.learnerProfile,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final AdminUserStatus status;
  final List<String> roles;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AdminCoachProfileSummary? coachProfile;
  final AdminLearnerProfileSummary? learnerProfile;

  bool get isCoach => roles.contains(AdminRoles.coach);
  bool get isAdmin => roles.contains(AdminRoles.admin);

  /// Name to show; falls back to the email when the profile has no name.
  String get displayName => fullName.isNotEmpty ? fullName : email;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final coach = json['coachProfile'];
    final learner = json['learnerProfile'];
    return AdminUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      dateOfBirth: DateFormatter.parseUtc(json['dateOfBirth'] as String?),
      status: AdminUserStatus.parse(json['status'] as String?),
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
      updatedAt: DateFormatter.parseUtc(json['updatedAt'] as String?),
      coachProfile: coach is Map<String, dynamic>
          ? AdminCoachProfileSummary.fromJson(coach)
          : null,
      learnerProfile: learner is Map<String, dynamic>
          ? AdminLearnerProfileSummary.fromJson(learner)
          : null,
    );
  }
}

/// `CoachProfileSummaryResponse` embedded in [AdminUser].
class AdminCoachProfileSummary {
  const AdminCoachProfileSummary({
    this.headline,
    this.bio,
    this.experienceYears,
    this.coverImageUrl,
    this.rating = 0,
    this.totalReviews = 0,
  });

  final String? headline;
  final String? bio;
  final int? experienceYears;
  final String? coverImageUrl;
  final num rating;
  final int totalReviews;

  factory AdminCoachProfileSummary.fromJson(Map<String, dynamic> json) {
    return AdminCoachProfileSummary(
      headline: json['headline'] as String?,
      bio: json['bio'] as String?,
      experienceYears: (json['experienceYears'] as num?)?.toInt(),
      coverImageUrl: json['coverImageUrl'] as String?,
      rating: json['rating'] as num? ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }
}

/// `LearnerProfileSummaryResponse` embedded in [AdminUser].
class AdminLearnerProfileSummary {
  const AdminLearnerProfileSummary({this.goal});

  final String? goal;

  factory AdminLearnerProfileSummary.fromJson(Map<String, dynamic> json) =>
      AdminLearnerProfileSummary(goal: json['goal'] as String?);
}

/// `AdminUserFilterRequest` — query of `GET /api/admin/users`.
class AdminUserFilter {
  const AdminUserFilter({this.search = '', this.role, this.status});

  final String search;
  final String? role;
  final AdminUserStatus? status;

  bool get hasActiveFilters =>
      search.isNotEmpty || role != null || status != null;

  AdminUserFilter copyWith({
    String? search,
    String? role,
    AdminUserStatus? status,
    bool clearRole = false,
    bool clearStatus = false,
  }) {
    return AdminUserFilter(
      search: search ?? this.search,
      role: clearRole ? null : (role ?? this.role),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

/// `AdminCreateUserRequest`. Field rules mirror `AdminCreateUserRequestValidator`.
class AdminCreateUserRequest {
  const AdminCreateUserRequest({
    required this.email,
    required this.fullName,
    required this.password,
    required this.status,
    required this.roles,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
  });

  final String email;
  final String fullName;
  final String password;
  final AdminUserStatus status;
  final List<String> roles;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;

  Map<String, dynamic> toJson() => {
    'email': email,
    'fullName': fullName,
    'password': password,
    'status': status.wireValue,
    'roles': roles,
    'phone': ?_nullIfBlank(phone),
    'avatarUrl': ?_nullIfBlank(avatarUrl),
    'dateOfBirth': ?dateOfBirth?.toUtc().toIso8601String(),
  };
}

/// `AdminUpdateUserRequest` — no email and no password: the backend update
/// endpoint does not accept them, so the edit form never sends them.
class AdminUpdateUserRequest {
  const AdminUpdateUserRequest({
    required this.fullName,
    required this.status,
    required this.roles,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
  });

  final String fullName;
  final AdminUserStatus status;
  final List<String> roles;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'status': status.wireValue,
    'roles': roles,
    'phone': ?_nullIfBlank(phone),
    'avatarUrl': ?_nullIfBlank(avatarUrl),
    'dateOfBirth': ?dateOfBirth?.toUtc().toIso8601String(),
  };
}

String? _nullIfBlank(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
