import '../../../../../core/utils/date_formatter.dart';
import '../../../shared/models/admin_status.dart';

/// `ReviewReportResponse` — a report filed against a coach review.
class ReviewReport {
  const ReviewReport({
    required this.id,
    required this.reporterId,
    required this.reviewId,
    this.reason,
    this.description,
    this.status = ReviewReportStatus.unknown,
    this.actionTaken,
    this.handledByUserId,
    this.handledAt,
    this.resolutionNote,
    this.createdAt,
    this.reviewRating,
    this.reviewComment,
    this.reviewStatus,
    this.reviewCoachId,
    this.reviewLearnerId,
  });

  final String id;
  final String reporterId;
  final String reviewId;
  final String? reason;
  final String? description;
  final ReviewReportStatus status;
  final String? actionTaken;
  final String? handledByUserId;
  final DateTime? handledAt;
  final String? resolutionNote;
  final DateTime? createdAt;

  // Snapshot of the reported review (all nullable in the DTO).
  final int? reviewRating;
  final String? reviewComment;
  final String? reviewStatus;
  final String? reviewCoachId;
  final String? reviewLearnerId;

  factory ReviewReport.fromJson(Map<String, dynamic> json) {
    return ReviewReport(
      id: json['id'] as String? ?? '',
      reporterId: json['reporterId'] as String? ?? '',
      reviewId: json['reviewId'] as String? ?? '',
      reason: json['reason'] as String?,
      description: json['description'] as String?,
      status: ReviewReportStatus.parse(json['status'] as String?),
      actionTaken: json['actionTaken'] as String?,
      handledByUserId: json['handledByUserId'] as String?,
      handledAt: DateFormatter.parseUtc(json['handledAt'] as String?),
      resolutionNote: json['resolutionNote'] as String?,
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
      reviewRating: (json['reviewRating'] as num?)?.toInt(),
      reviewComment: json['reviewComment'] as String?,
      reviewStatus: json['reviewStatus'] as String?,
      reviewCoachId: json['reviewCoachId'] as String?,
      reviewLearnerId: json['reviewLearnerId'] as String?,
    );
  }
}

/// `ResolveReviewReportRequest`.
///
/// The backend has exactly three inputs — there are no moderation "actions" to
/// pick from: `isValid` decides whether the report is upheld (`resolved`) or
/// dismissed (`rejected`), and `hideOrDeleteReview` decides whether an upheld
/// report also hides the review.
class ResolveReviewReportRequest {
  const ResolveReviewReportRequest({
    required this.isValid,
    required this.hideOrDeleteReview,
    this.resolutionNote,
  });

  final bool isValid;
  final bool hideOrDeleteReview;
  final String? resolutionNote;

  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'hideOrDeleteReview': hideOrDeleteReview,
    'resolutionNote': ?_nullIfBlank(resolutionNote),
  };
}

String? _nullIfBlank(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
