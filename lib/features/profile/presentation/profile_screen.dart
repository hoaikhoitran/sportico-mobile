import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/data/models/current_user.dart';
import '../../auth/presentation/auth_controller.dart';

/// Account tab: profile summary (`GET /api/users/me`), role-aware shortcuts,
/// client-side logout (no logout endpoint exists on the backend).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.xs,
            AppSpacing.screenH,
            AppSpacing.xl,
          ),
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.accentBlueSoft,
                    foregroundImage: user?.avatarUrl != null
                        ? CachedNetworkImageProvider(user!.avatarUrl!)
                        : null,
                    child: Text(
                      _initials(user?.fullName ?? '?'),
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Đang tải…',
                          style: AppTextStyles.sectionTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: AppTextStyles.bodySecondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xxs,
                          children: [
                            for (final role in auth.roles)
                              AppBadge(
                                label: _roleLabel(role),
                                tone: role == Roles.coach
                                    ? AppBadgeTone.brand
                                    : AppBadgeTone.info,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (auth.isCoach) ...[
              Text('Huấn luyện viên', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Gói tập của tôi',
                      onTap: () => context.push(RouteNames.coachPackages),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.assignment_outlined,
                      title: 'Học viên đăng ký',
                      onTap: () => context.push(RouteNames.coachBookings),
                    ),
                    const Divider(indent: 52),
                    _MenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Ví & giao dịch',
                      onTap: () => context.push(RouteNames.coachWallet),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_rounded,
                          color: AppColors.accentOrange,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Trở thành huấn luyện viên',
                            style: AppTextStyles.cardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tạo gói tập, quản lý học viên và nhận thu nhập từ '
                      'các buổi tập hoàn thành.',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Đăng ký làm HLV',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.medium,
                      onPressed: () => context.push(RouteNames.coachOnboarding),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Chung', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Đơn đăng ký của tôi',
                    onTap: () => context.push(RouteNames.bookings),
                  ),
                  const Divider(indent: 52),
                  _MenuTile(
                    icon: Icons.notifications_outlined,
                    title: 'Thông báo',
                    onTap: () => context.push(RouteNames.notifications),
                  ),
                  const Divider(indent: 52),
                  _MenuTile(
                    icon: Icons.edit_outlined,
                    title: 'Chỉnh sửa hồ sơ',
                    onTap: user == null
                        ? () {}
                        : () => _showSheet(
                            context,
                            _EditProfileSheet(user: user),
                          ),
                  ),
                  const Divider(indent: 52),
                  _MenuTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Đổi mật khẩu',
                    onTap: () =>
                        _showSheet(context, const _ChangePasswordSheet()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Đăng xuất',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.destructive,
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showSheet(BuildContext context, Widget sheet) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => sheet,
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi Sportico?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _roleLabel(String role) => switch (role) {
    Roles.learner => 'Người tập',
    Roles.coach => 'Huấn luyện viên',
    Roles.admin => 'Quản trị viên',
    _ => role,
  };
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTextStyles.cardTitle),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

/// Edits full name and phone (`PUT /api/users/me`).
class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user});

  final CurrentUser user;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: widget.user.phone ?? '');
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final error = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          fullName: _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    AppSnackBar.success(context, 'Đã cập nhật hồ sơ.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Chỉnh sửa hồ sơ', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Họ và tên',
              controller: _name,
              validator: Validators.fullName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Số điện thoại (tùy chọn)',
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Lưu thay đổi',
              onPressed: _submit,
              loading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}

/// `POST /api/auth/change-password`.
class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case ApiSuccess():
        AppSnackBar.success(context, 'Đã đổi mật khẩu.');
        Navigator.of(context).pop();
      case ApiFailure(:final error):
        AppSnackBar.error(context, error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Đổi mật khẩu', style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Mật khẩu hiện tại',
              controller: _current,
              obscureText: true,
              validator: Validators.password,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Mật khẩu mới',
              controller: _next,
              hint: 'Tối thiểu 8 ký tự',
              obscureText: _obscure,
              validator: Validators.password,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              suffix: IconButton(
                tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Đổi mật khẩu',
              onPressed: _submit,
              loading: _submitting,
            ),
          ],
        ),
      ),
    );
  }
}
