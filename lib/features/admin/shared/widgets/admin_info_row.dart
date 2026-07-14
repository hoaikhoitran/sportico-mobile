import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';

/// Compact `label → value` row used across admin detail screens.
///
/// [copyable] adds a copy button — used for payout/transaction references an
/// admin needs to paste into the bank or PayOS console.
class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueWidget,
    this.copyable = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
  final bool copyable;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: AppTextStyles.bodySecondary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value,
                  style: emphasize
                      ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)
                      : AppTextStyles.body,
                ),
          ),
          if (copyable && value != '—')
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  AppSnackBar.info(context, 'Đã sao chép $label.');
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: AppColors.textSecondary,
              tooltip: 'Sao chép',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
        ],
      ),
    );
  }
}
