import '../../../../core/utils/date_formatter.dart';

/// `NotificationResponse` (docs/api/notifications.md). `type` values come
/// from `NotificationTypeConstants`; unknown types are kept raw.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.content,
    required this.type,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? content;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      type: json['type'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
    );
  }
}
