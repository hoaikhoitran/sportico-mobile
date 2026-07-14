import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../shared/presentation/admin_mutation_controller.dart';

/// Approve / reject pair used by every moderation surface.
///
/// Both buttons are disabled while *either* action is running, and the running
/// one shows a spinner — so an admin can neither double-approve nor approve and
/// reject the same item at once.
class ModerationActionBar extends ConsumerWidget {
  const ModerationActionBar({
    super.key,
    required this.approveKey,
    required this.rejectKey,
    required this.onApprove,
    required this.onReject,
    this.approveLabel = 'Phê duyệt',
    this.rejectLabel = 'Từ chối',
    this.dense = false,
  });

  final String approveKey;
  final String rejectKey;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String approveLabel;
  final String rejectLabel;

  /// Compact variant for list cards.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approving = ref.watch(adminMutationBusyProvider(approveKey));
    final rejecting = ref.watch(adminMutationBusyProvider(rejectKey));
    final busy = approving || rejecting;
    final size = dense ? AppButtonSize.small : AppButtonSize.medium;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: rejectLabel,
            icon: Icons.close_rounded,
            variant: AppButtonVariant.secondary,
            size: size,
            loading: rejecting,
            onPressed: busy ? null : onReject,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppButton(
            label: approveLabel,
            icon: Icons.check_rounded,
            size: size,
            loading: approving,
            onPressed: busy ? null : onApprove,
          ),
        ),
      ],
    );
  }
}

/// Sticky bottom action area for detail screens.
class AdminBottomActionBar extends StatelessWidget {
  const AdminBottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.sm,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}
