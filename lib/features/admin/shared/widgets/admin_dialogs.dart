import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

/// Confirmation for an action that changes money, access or visibility.
///
/// Returns `true` only when the admin explicitly confirms.
Future<bool> showAdminConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Hủy',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: AppTextStyles.body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: AppColors.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Bottom sheet that collects the note/reason attached to a rejection.
///
/// [reasonRequired] mirrors the backend validator: the training-package
/// rejection reason is `NotEmpty`, while a payout-account note is optional.
/// Returns the entered text, or `null` when the admin backs out.
Future<String?> showAdminRejectReasonSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String submitLabel,
  String? hint,
  String? description,
  bool reasonRequired = true,
  int maxLength = 1000,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _RejectReasonSheet(
      title: title,
      label: label,
      submitLabel: submitLabel,
      hint: hint,
      description: description,
      reasonRequired: reasonRequired,
      maxLength: maxLength,
    ),
  );
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet({
    required this.title,
    required this.label,
    required this.submitLabel,
    required this.reasonRequired,
    required this.maxLength,
    this.hint,
    this.description,
  });

  final String title;
  final String label;
  final String submitLabel;
  final bool reasonRequired;
  final int maxLength;
  final String? hint;
  final String? description;

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (widget.reasonRequired && text.isEmpty) {
      return 'Vui lòng nhập ${widget.label.toLowerCase()}.';
    }
    if (text.length > widget.maxLength) {
      return '${widget.label} tối đa ${widget.maxLength} ký tự.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTextStyles.sectionTitle),
            if (widget.description != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(widget.description!, style: AppTextStyles.bodySecondary),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _controller,
              validator: _validate,
              autofocus: true,
              maxLines: 4,
              maxLength: widget.maxLength,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                labelText: widget.reasonRequired
                    ? widget.label
                    : '${widget.label} (không bắt buộc)',
                hintText: widget.hint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Hủy',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: widget.submitLabel,
                    variant: AppButtonVariant.destructive,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
