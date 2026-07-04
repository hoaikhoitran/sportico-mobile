import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Lightweight loading skeletons with a soft shimmer sweep.
///
/// No external dependency — a single [AnimationController] drives a gradient
/// that slides across grey placeholder blocks, so a loading screen reads as
/// "content is arriving" instead of a frozen spinner. Use [AppSkeletonList] as
/// a drop-in replacement for `AppLoading` on list screens.

/// Shared shimmer clock. Wrap any tree of [AppSkeletonBox]es in this to make
/// them pulse together.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          _ShimmerScope(t: _controller.value, child: child!),
      child: widget.child,
    );
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.t, required super.child});

  /// Animation progress, 0 → 1.
  final double t;

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();
    return scope?.t ?? 0;
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) => oldWidget.t != t;
}

/// A single shimmering placeholder block. Must sit under an [AppShimmer].
class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppSpacing.radiusSm,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final t = _ShimmerScope.of(context);
    // A 2-unit-wide highlight window slides from just off the left edge to
    // just off the right edge as t goes 0 → 1.
    final begin = Alignment(-2 + 2 * t, 0);
    final end = Alignment(2 * t, 0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(radius)
            : null,
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: const [
            AppColors.surfaceContainerHighest,
            AppColors.surfaceContainerLowest,
            AppColors.surfaceContainerHighest,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

/// Placeholder that mirrors a session/list card: leading square, two text
/// lines, and a trailing status pill.
class _SkeletonListCard extends StatelessWidget {
  const _SkeletonListCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const AppSkeletonBox(width: 40, height: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonBox(
                  width: 150,
                  height: 12,
                  radius: AppSpacing.radiusXs,
                ),
                SizedBox(height: AppSpacing.xs),
                AppSkeletonBox(
                  width: 90,
                  height: 10,
                  radius: AppSpacing.radiusXs,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const AppSkeletonBox(
            width: 58,
            height: 18,
            radius: AppSpacing.radiusFull,
          ),
        ],
      ),
    );
  }
}

/// Drop-in loading placeholder for list screens.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({
    super.key,
    this.itemCount = 6,
    this.showDayHeaders = true,
    this.padding,
  });

  final int itemCount;
  final bool showDayHeaders;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding:
            padding ??
            const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              AppSpacing.xl,
            ),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (showDayHeaders && (i == 0 || i == 3)) ...[
              if (i != 0) const SizedBox(height: AppSpacing.sm),
              const AppSkeletonBox(
                width: 120,
                height: 12,
                radius: AppSpacing.radiusXs,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const _SkeletonListCard(),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
