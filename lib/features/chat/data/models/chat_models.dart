import '../../../../core/utils/date_formatter.dart';

/// `ChatRoomResponse` — one room per user–coach pair.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.createdAt,
  });

  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime? createdAt;

  /// The other participant from the current user's perspective.
  String counterpartId(String myUserId) =>
      user1Id == myUserId ? user2Id : user1Id;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String? ?? '',
      user1Id: json['user1Id'] as String? ?? '',
      user2Id: json['user2Id'] as String? ?? '',
      createdAt: DateFormatter.parseUtc(json['createdAt'] as String?),
    );
  }
}

/// `ChatMessageResponse`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    this.sentAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime? sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      sentAt: DateFormatter.parseUtc(json['sentAt'] as String?),
    );
  }
}

/// Minimal public profile (`GET /api/users/{id}`, docs/api/users.md) used to
/// label chat rooms with the counterpart's name and avatar.
class PublicUserLite {
  const PublicUserLite({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;

  factory PublicUserLite.fromJson(Map<String, dynamic> json) {
    return PublicUserLite(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
