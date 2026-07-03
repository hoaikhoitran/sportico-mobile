import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

enum AppButtonSize { large, medium, small }

/// Single button component for the whole app — enforces the CTA hierarchy.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;

  /// Fills the available width (default for main CTAs).
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.large => 50.0,
      AppButtonSize.medium => 44.0,
      AppButtonSize.small => 36.0,
    };
    final textStyle = AppTextStyles.button.copyWith(
      fontSize: size == AppButtonSize.small ? 13.5 : 15,
    );
    final effectiveOnPressed = loading ? null : onPressed;

    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color:
                  variant == AppButtonVariant.primary ||
                      variant == AppButtonVariant.destructive
                  ? Colors.white
                  : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: size == AppButtonSize.small ? 16 : 19),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );
    final padding = EdgeInsets.symmetric(
      horizontal: size == AppButtonSize.small ? AppSpacing.sm : AppSpacing.lg,
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, height),
          padding: padding,
          textStyle: textStyle,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, height),
          padding: padding,
          backgroundColor: AppColors.danger,
          textStyle: textStyle,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, height),
          padding: padding,
          textStyle: textStyle,
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: effectiveOnPressed,
        style: TextButton.styleFrom(
          minimumSize: Size(0, height),
          padding: padding,
          textStyle: textStyle,
          shape: shape,
        ),
        child: child,
      ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
