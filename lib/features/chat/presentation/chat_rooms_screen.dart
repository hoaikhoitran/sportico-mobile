import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_error.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/chat_models.dart';
import 'chat_controller.dart';

/// Messages tab: the user's chat rooms. Starting a NEW conversation is not
/// available in phase 1 (`POST /api/chat/rooms` is outside the allow-list).
class ChatRoomsScreen extends ConsumerWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(chatRoomsProvider);
    final myUserId = ref.watch(authControllerProvider).user?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      body: SafeArea(
        child: switch (rooms) {
          AsyncData(:final value) =>
            value.isEmpty
                ? const AppEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chưa có cuộc trò chuyện',
                    message:
                        'Các cuộc trò chuyện với huấn luyện viên/học viên sẽ '
                        'xuất hiện tại đây.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(chatRoomsProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        AppSpacing.xs,
                        AppSpacing.screenH,
                        AppSpacing.xl,
                      ),
                      itemCount: value.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) =>
                          _RoomTile(room: value[index], myUserId: myUserId),
                    ),
                  ),
          AsyncError(:final error) => AppErrorState(
            error: error is ApiError ? error : null,
            onRetry: () => ref.invalidate(chatRoomsProvider),
          ),
          _ => const AppLoading(),
        },
      ),
    );
  }
}

class _RoomTile extends ConsumerWidget {
  const _RoomTile({required this.room, required this.myUserId});

  final ChatRoom room;
  final String myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterpartId = room.counterpartId(myUserId);
    final counterpart = ref.watch(publicUserProvider(counterpartId)).value;
    final name = counterpart?.fullName.isNotEmpty == true
        ? counterpart!.fullName
        : 'Người dùng';

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: () =>
          context.push(RouteNames.chatDetailPath(room.id), extra: name),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.accentBlueSoft,
            foregroundImage: counterpart?.avatarUrl != null
                ? CachedNetworkImageProvider(counterpart!.avatarUrl!)
                : null,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.cardTitle.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Bắt đầu ${DateFormatter.date(room.createdAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
