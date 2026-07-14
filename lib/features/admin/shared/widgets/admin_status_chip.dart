import 'package:flutter/material.dart';

import '../../../../core/widgets/app_badge.dart';

/// Status pill for the admin area.
///
/// A thin wrapper over [AppBadge] so status colors keep coming from the shared
/// design tokens: every admin status enum exposes `label` + `tone`, and this is
/// the only place that renders them.
class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) => AppBadge(label: label, tone: tone);
}
