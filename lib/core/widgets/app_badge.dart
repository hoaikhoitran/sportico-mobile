import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum AppBadgeTone { neutral, info, success, warning, danger, brand }

/// Small status pill (booking status, session status, package status…).
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.tone});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      AppBadgeTone.neutral => (AppColors.surfaceMuted, AppColors.textSecondary),
      AppBadgeTone.info => (AppColors.infoSoft, AppColors.info),
      AppBadgeTone.success => (AppColors.successSoft, AppColors.success),
      AppBadgeTone.warning => (AppColors.warningSoft, AppColors.warning),
      AppBadgeTone.danger => (AppColors.dangerSoft, AppColors.danger),
      AppBadgeTone.brand => (AppColors.accentBlueSoft, AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        // A pill is always one line: in a narrow slot (grid cards) a wrapping
        // label would grow the badge into a multi-line block.
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: foreground,
          height: 1.3,
        ),
      ),
    );
  }
}
