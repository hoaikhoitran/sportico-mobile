import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exceptions.dart';
import '../../../core/network/paged_result.dart';
import 'models/chat_models.dart';

/// docs/api/chat.md — list rooms, open a room with a coach, read messages,
/// send.
class ChatApi {
  ChatApi(this._dio);

  final Dio _dio;

  /// Plain list (not paged), newest first.
  Future<ApiResult<List<ChatRoom>>> rooms() {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.chatRooms),
      (data) => (data as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatRoom.fromJson)
          .toList(),
    );
  }

  /// Opens (or returns the existing) 1-1 room with a coach.
  Future<ApiResult<ChatRoom>> createRoom(String coachId) {
    return safeApiCall(
      () => _dio.post(ApiEndpoints.chatRooms, data: {'coachId': coachId}),
      (data) => ChatRoom.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PagedResult<ChatMessage>>> messages(
    String roomId, {
    int pageNumber = 1,
    int pageSize = 30,
  }) {
    return safeApiCall(
      () => _dio.get(
        ApiEndpoints.chatMessages(roomId),
        queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
      ),
      (data) => PagedResult.fromJson(
        data as Map<String, dynamic>,
        ChatMessage.fromJson,
      ),
    );
  }

  Future<ApiResult<ChatMessage>> send(String roomId, String content) {
    return safeApiCall(
      () => _dio.post(
        ApiEndpoints.chatMessages(roomId),
        data: {'content': content},
      ),
      (data) => ChatMessage.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Public profile lookup for room labels (anonymous endpoint).
  Future<ApiResult<PublicUserLite>> publicUser(String userId) {
    return safeApiCall(
      () => _dio.get(ApiEndpoints.publicUser(userId)),
      (data) => PublicUserLite.fromJson(data as Map<String, dynamic>),
    );
  }
}

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(dioProvider));
});
