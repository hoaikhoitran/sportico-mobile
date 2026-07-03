import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/api_result.dart';
import '../data/chat_api.dart';
import '../data/models/chat_models.dart';

final chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoom>>((
  ref,
) async {
  final result = await ref.watch(chatApiProvider).rooms();
  return switch (result) {
    ApiSuccess(:final data) => data,
    ApiFailure(:final error) => throw error,
  };
});

/// Counterpart profile for room labels, cached per user id.
final publicUserProvider = FutureProvider.autoDispose
    .family<PublicUserLite?, String>((ref, userId) async {
      final result = await ref.watch(chatApiProvider).publicUser(userId);
      return switch (result) {
        ApiSuccess(:final data) => data,
        // A failed lookup only degrades the label, never the room list.
        ApiFailure() => null,
      };
    });

class ChatMessagesState {
  const ChatMessagesState({
    required this.messages,
    required this.hasOlder,
    required this.oldestLoadedPage,
    this.loadingOlder = false,
  });

  /// Newest first (page 1 of the backend).
  final List<ChatMessage> messages;
  final bool hasOlder;
  final int oldestLoadedPage;
  final bool loadingOlder;

  ChatMessagesState copyWith({
    List<ChatMessage>? messages,
    bool? hasOlder,
    int? oldestLoadedPage,
    bool? loadingOlder,
  }) => ChatMessagesState(
    messages: messages ?? this.messages,
    hasOlder: hasOlder ?? this.hasOlder,
    oldestLoadedPage: oldestLoadedPage ?? this.oldestLoadedPage,
    loadingOlder: loadingOlder ?? this.loadingOlder,
  );
}

/// Messages of one room with light polling (no websocket on the backend).
/// The poll timer lives with the provider: `autoDispose` cancels it as soon
/// as the chat screen is closed.
class ChatMessagesController extends AsyncNotifier<ChatMessagesState> {
  ChatMessagesController(this.roomId);

  final String roomId;

  Timer? _pollTimer;

  @override
  Future<ChatMessagesState> build() async {
    ref.onDispose(() => _pollTimer?.cancel());
    _pollTimer = Timer.periodic(
      AppConfig.chatPollInterval,
      (_) => _pollNewest(),
    );

    final page = await _fetchPage(1);
    return ChatMessagesState(
      messages: page.$1,
      hasOlder: page.$2,
      oldestLoadedPage: 1,
    );
  }

  /// Returns (messages, hasNext) of one page — newest first.
  Future<(List<ChatMessage>, bool)> _fetchPage(int pageNumber) async {
    final result = await ref
        .read(chatApiProvider)
        .messages(roomId, pageNumber: pageNumber);
    return switch (result) {
      ApiSuccess(:final data) => (data.items, data.hasNext),
      ApiFailure(:final error) => throw error,
    };
  }

  /// Merges freshly sent/received messages without disturbing older pages.
  Future<void> _pollNewest() async {
    final current = state.value;
    if (current == null) return;
    try {
      final (newest, _) = await _fetchPage(1);
      final known = current.messages.map((m) => m.id).toSet();
      final incoming = newest
          .where((m) => !known.contains(m.id))
          .toList(growable: false);
      if (incoming.isEmpty) return;
      state = AsyncData(
        current.copyWith(messages: [...incoming, ...current.messages]),
      );
    } on ApiError {
      // Silent — polling must never surface transient errors.
    }
  }

  Future<void> loadOlder() async {
    final current = state.value;
    if (current == null || !current.hasOlder || current.loadingOlder) return;

    state = AsyncData(current.copyWith(loadingOlder: true));
    try {
      final nextPage = current.oldestLoadedPage + 1;
      final (older, hasNext) = await _fetchPage(nextPage);
      final known = current.messages.map((m) => m.id).toSet();
      state = AsyncData(
        ChatMessagesState(
          messages: [
            ...current.messages,
            ...older.where((m) => !known.contains(m.id)),
          ],
          hasOlder: hasNext,
          oldestLoadedPage: nextPage,
        ),
      );
    } on ApiError {
      state = AsyncData(current.copyWith(loadingOlder: false));
    }
  }

  /// Returns the error to display, or null on success.
  Future<ApiError?> send(String content) async {
    final result = await ref.read(chatApiProvider).send(roomId, content);
    switch (result) {
      case ApiSuccess(data: final message):
        final current = state.value;
        if (current != null &&
            !current.messages.any((m) => m.id == message.id)) {
          state = AsyncData(
            current.copyWith(messages: [message, ...current.messages]),
          );
        }
        return null;
      case ApiFailure(:final error):
        return error;
    }
  }
}

final chatMessagesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ChatMessagesController, ChatMessagesState, String>(
      ChatMessagesController.new,
    );
