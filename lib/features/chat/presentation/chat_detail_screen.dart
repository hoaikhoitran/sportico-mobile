import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/chat_models.dart';
import 'chat_controller.dart';

/// One conversation. Messages poll lightly while the screen is open
/// (the poll timer dies with the provider on dispose).
class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.roomId, this.title});

  final String roomId;

  /// Counterpart name passed from the rooms list.
  final String? title;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Reversed list: "end" of scroll extent = oldest messages.
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 300) {
        ref
            .read(chatMessagesControllerProvider(widget.roomId).notifier)
            .loadOlder();
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() => _sending = true);
    final error = await ref
        .read(chatMessagesControllerProvider(widget.roomId).notifier)
        .send(content);
    if (!mounted) return;
    setState(() => _sending = false);

    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    _inputController.clear();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(
      chatMessagesControllerProvider(widget.roomId),
    );
    final myUserId = ref.watch(authControllerProvider).user?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Trò chuyện')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (messagesState) {
                AsyncData(:final value) =>
                  value.messages.isEmpty
                      ? Center(
                          child: Text(
                            'Hãy gửi lời chào đầu tiên!',
                            style: AppTextStyles.bodySecondary,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenH,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount:
                              value.messages.length + (value.hasOlder ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= value.messages.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.sm),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final message = value.messages[index];
                            final previous = index + 1 < value.messages.length
                                ? value.messages[index + 1]
                                : null;
                            return _MessageBubble(
                              message: message,
                              isMine: message.senderId == myUserId,
                              showTime:
                                  previous == null ||
                                  previous.senderId != message.senderId ||
                                  _minutesApart(previous, message) > 10,
                            );
                          },
                        ),
                AsyncError(:final error) => AppErrorState(
                  error: error is ApiError ? error : null,
                  onRetry: () => ref.invalidate(
                    chatMessagesControllerProvider(widget.roomId),
                  ),
                ),
                _ => const AppLoading(),
              },
            ),
            _InputBar(
              controller: _inputController,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  static int _minutesApart(ChatMessage a, ChatMessage b) {
    final at = a.sentAt, bt = b.sentAt;
    if (at == null || bt == null) return 0;
    return bt.difference(at).inMinutes.abs();
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.showTime,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxs,
            ),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                DateFormatter.dateTime(message.sentAt),
                style: AppTextStyles.caption,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs + 2,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.74,
          ),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : AppColors.surface,
            border: isMine ? null : Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppSpacing.radiusLg),
              topRight: const Radius.circular(AppSpacing.radiusLg),
              bottomLeft: Radius.circular(isMine ? AppSpacing.radiusLg : 4),
              bottomRight: Radius.circular(isMine ? 4 : AppSpacing.radiusLg),
            ),
          ),
          child: Text(
            message.content,
            style: AppTextStyles.body.copyWith(
              color: isMine ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          IconButton(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accentBlueSoft,
            ),
          ),
        ],
      ),
    );
  }
}
