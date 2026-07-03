import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/training_package.dart';

/// Catalog list item: sport, title, coach, schedule summary, price.
class PackageCard extends StatelessWidget {
  const PackageCard({super.key, required this.package, this.onTap});

  final TrainingPackage package;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final coach = package.coach;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppBadge(label: package.sportName, tone: AppBadgeTone.brand),
              const SizedBox(width: AppSpacing.xs),
              AppBadge(
                label: package.isOnline ? 'Online' : 'Trực tiếp',
                tone: package.isOnline
                    ? AppBadgeTone.info
                    : AppBadgeTone.success,
              ),
              const Spacer(),
              Text(
                '${package.sessionCount} buổi',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            package.title,
            style: AppTextStyles.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (coach != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                _CoachAvatar(coach: coach),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    coach.fullName,
                    style: AppTextStyles.bodySecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (coach.totalReviews > 0) ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    coach.rating.toStringAsFixed(1),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  package.isOnline
                      ? 'Tập online'
                      : (package.location ?? 'Chưa rõ địa điểm'),
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(package.priceLabel, style: AppTextStyles.price),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({required this.coach});

  final PackageCoachSummary coach;

  @override
  Widget build(BuildContext context) {
    final url = coach.avatarUrl;
    return CircleAvatar(
      radius: 11,
      backgroundColor: AppColors.accentBlueSoft,
      foregroundImage: url != null ? CachedNetworkImageProvider(url) : null,
      child: Text(
        coach.fullName.isNotEmpty ? coach.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
