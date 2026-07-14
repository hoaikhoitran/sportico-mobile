import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../data/admin_identity.dart';

/// Avatar + name of the person behind an id (coach, reporter, learner).
///
/// The moderation/finance DTOs only carry the id, so the name is resolved
/// through the cached [adminUserIdentityProvider]. While it loads, the row
/// shows a muted placeholder rather than a raw UUID; if the lookup fails the
/// placeholder stays — the surrounding card is still fully usable.
class AdminIdentityLine extends ConsumerWidget {
  const AdminIdentityLine({
    super.key,
    required this.userId,
    this.prefix,
    this.showEmail = false,
    this.avatarSize = 28,
  });

  final String userId;
  final String? prefix;
  final bool showEmail;
  final double avatarSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(adminUserIdentityProvider(userId));
    final user = identity.value;

    final name = switch (identity) {
      AsyncData(value: final u?) => u.displayName,
      AsyncLoading() => 'Đang tải…',
      _ => 'Không xác định',
    };

    final avatarUrl = user?.avatarUrl;

    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const _AvatarFallback(),
                  placeholder: (_, _) => const _AvatarFallback(),
                )
              : const _AvatarFallback(),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prefix != null ? '$prefix $name' : name,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showEmail && user != null && user.email.isNotEmpty)
                Text(
                  user.email,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) => const Icon(
    Icons.person_rounded,
    size: 16,
    color: AppColors.textSecondary,
  );
}
