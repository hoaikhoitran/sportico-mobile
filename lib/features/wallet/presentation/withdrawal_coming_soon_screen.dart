import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

/// Phase-1 placeholder — withdrawal requests are intentionally NOT available
/// on mobile (`POST /api/coaches/me/withdrawal-requests` is never called).
class WithdrawalComingSoonScreen extends StatelessWidget {
  const WithdrawalComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rút tiền')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accentOrangeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  size: 36,
                  color: AppColors.accentOrange,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Tính năng rút tiền sẽ được hỗ trợ sau',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Trong thời gian này, bạn có thể theo dõi số dư và lịch sử '
                'giao dịch trong ví. Vui lòng sử dụng phiên bản web để tạo '
                'yêu cầu rút tiền.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  'Lưu ý: phí nền tảng đã được khấu trừ khi học viên mua gói. '
                  'Không có khoản phí nào bị trừ thêm khi rút tiền.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.info),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
