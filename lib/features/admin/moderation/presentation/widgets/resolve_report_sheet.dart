import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../data/models/review_report.dart';

/// Collects the exact three fields of `ResolveReviewReportRequest`.
///
/// There is no free-form "action" list on the backend: upholding the report
/// resolves it (optionally hiding the review), dismissing it rejects the
/// report and leaves the review untouched.
Future<ResolveReviewReportRequest?> showResolveReportSheet(
  BuildContext context,
) {
  return showModalBottomSheet<ResolveReviewReportRequest>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _ResolveReportSheet(),
  );
}

class _ResolveReportSheet extends StatefulWidget {
  const _ResolveReportSheet();

  @override
  State<_ResolveReportSheet> createState() => _ResolveReportSheetState();
}

class _ResolveReportSheetState extends State<_ResolveReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  bool _isValid = true;
  bool _hideReview = true;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      ResolveReviewReportRequest(
        isValid: _isValid,
        // Only an upheld report can hide the review.
        hideOrDeleteReview: _isValid && _hideReview,
        resolutionNote: _noteController.text.trim(),
      ),
    );
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
            Text('Xử lý báo cáo', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),

            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Hợp lệ'),
                  icon: Icon(Icons.flag_rounded, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Bác bỏ'),
                  icon: Icon(Icons.do_not_disturb_on_rounded, size: 16),
                ),
              ],
              selected: {_isValid},
              onSelectionChanged: (selection) =>
                  setState(() => _isValid = selection.first),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isValid
                  ? 'Báo cáo được chấp nhận. Đánh giá có thể bị ẩn khỏi hồ sơ '
                        'huấn luyện viên.'
                  : 'Báo cáo bị bác bỏ. Đánh giá vẫn hiển thị bình thường.',
              style: AppTextStyles.bodySecondary,
            ),

            if (_isValid) ...[
              const SizedBox(height: AppSpacing.xs),
              SwitchListTile.adaptive(
                value: _hideReview,
                onChanged: (value) => setState(() => _hideReview = value),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Ẩn đánh giá bị báo cáo',
                  style: AppTextStyles.body,
                ),
                subtitle: Text(
                  'Điểm đánh giá của huấn luyện viên sẽ được tính lại.',
                  style: AppTextStyles.caption,
                ),
                activeThumbColor: AppColors.primary,
              ),
            ],

            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 1000,
              style: AppTextStyles.body,
              validator: (value) => (value?.trim().length ?? 0) > 1000
                  ? 'Ghi chú tối đa 1000 ký tự.'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Ghi chú xử lý (không bắt buộc)',
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
                  child: AppButton(label: 'Xác nhận', onPressed: _submit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
