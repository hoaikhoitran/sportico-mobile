import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../moderation/presentation/widgets/moderation_action_bar.dart';
import '../../shared/models/admin_status.dart';
import '../../shared/presentation/admin_mutation_controller.dart';
import '../../shared/widgets/admin_section_header.dart';
import '../data/models/admin_user.dart';
import 'admin_users_controller.dart';

/// Create (`userId == null`) or edit an account.
///
/// The two backend requests differ: `AdminCreateUserRequest` carries email and
/// password, `AdminUpdateUserRequest` carries neither — so the edit form never
/// shows, and never submits, those read-only fields.
class AdminUserFormScreen extends ConsumerWidget {
  const AdminUserFormScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = userId != null;

    if (!isEdit) {
      return const _UserForm();
    }

    final state = ref.watch(adminUserDetailProvider(userId!));
    return switch (state) {
      AsyncData(:final value) => _UserForm(existing: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa người dùng')),
        body: AppErrorState(
          error: error is ApiError ? error : null,
          onRetry: () => ref.invalidate(adminUserDetailProvider(userId!)),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa người dùng')),
        body: const AppLoading(),
      ),
    };
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({this.existing});

  final AdminUser? existing;

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _email;
  late final TextEditingController _fullName;
  late final TextEditingController _password;
  late final TextEditingController _phone;
  late final TextEditingController _avatarUrl;

  late AdminUserStatus _status;
  late Set<String> _roles;
  DateTime? _dateOfBirth;

  bool _obscurePassword = true;
  bool _dirty = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final user = widget.existing;
    _email = TextEditingController(text: user?.email ?? '');
    _fullName = TextEditingController(text: user?.fullName ?? '');
    _password = TextEditingController();
    _phone = TextEditingController(text: user?.phone ?? '');
    _avatarUrl = TextEditingController(text: user?.avatarUrl ?? '');
    _dateOfBirth = user?.dateOfBirth;

    // Prefill exactly what the backend returned; a brand-new account defaults
    // to an active learner, the most common case.
    _status = user != null && user.status != AdminUserStatus.unknown
        ? user.status
        : AdminUserStatus.active;
    _roles = user != null && user.roles.isNotEmpty
        ? user.roles.toSet()
        : {AdminRoles.learner};

    for (final controller in [
      _email,
      _fullName,
      _password,
      _phone,
      _avatarUrl,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _email,
      _fullName,
      _password,
      _phone,
      _avatarUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  String get _mutationKey => _isEdit
      ? adminMutationKey('update-user', widget.existing!.id)
      : adminMutationKey('create-user', 'new');

  // ── Validators (mirror the backend FluentValidation rules) ────────────────
  static final _phonePattern = RegExp(r'^[0-9+\-\s().]+$');

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 20) return 'Số điện thoại tối đa 20 ký tự.';
    if (!_phonePattern.hasMatch(text)) {
      return 'Số điện thoại chỉ gồm chữ số và các ký tự + - ( ) . khoảng trắng.';
    }
    return null;
  }

  String? _validateAvatarUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (text.length > 1000) return 'Đường dẫn ảnh tối đa 1000 ký tự.';
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Đường dẫn ảnh phải là URL đầy đủ (https://…).';
    }
    return null;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      // The backend rejects a future date of birth.
      lastDate: now,
      helpText: 'Chọn ngày sinh',
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dirty = true;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roles.isEmpty) {
      AppSnackBar.error(context, 'Vui lòng chọn ít nhất một vai trò.');
      return;
    }

    final controller = ref.read(adminUsersControllerProvider.notifier);
    final ApiError? error;

    if (_isEdit) {
      error = await controller.edit(
        widget.existing!.id,
        AdminUpdateUserRequest(
          fullName: _fullName.text.trim(),
          status: _status,
          roles: _roles.toList(),
          phone: _phone.text,
          avatarUrl: _avatarUrl.text,
          dateOfBirth: _dateOfBirth,
        ),
      );
    } else {
      error = await controller.create(
        AdminCreateUserRequest(
          email: _email.text.trim(),
          fullName: _fullName.text.trim(),
          password: _password.text,
          status: _status,
          roles: _roles.toList(),
          phone: _phone.text,
          avatarUrl: _avatarUrl.text,
          dateOfBirth: _dateOfBirth,
        ),
      );
    }

    if (!mounted) return;
    if (error != null) {
      // Validation details from the backend land here verbatim.
      AppSnackBar.error(context, error.userMessage);
      return;
    }
    AppSnackBar.success(
      context,
      _isEdit ? 'Đã cập nhật tài khoản.' : 'Đã tạo tài khoản.',
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    final leave = await showAdminConfirmationDiscard(context);
    if (leave && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(adminMutationBusyProvider(_mutationKey));

    return PopScope(
      canPop: !_dirty || busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Chỉnh sửa người dùng' : 'Tạo tài khoản'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                AppSpacing.xl,
              ),
              children: [
                const AdminSectionHeader(title: 'Thông tin cơ bản'),

                if (!_isEdit) ...[
                  AppTextField(
                    label: 'Email',
                    controller: _email,
                    hint: 'nguoidung@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ] else ...[
                  // Email is not part of AdminUpdateUserRequest — shown as a
                  // read-only reference so it is never submitted.
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Email: ${widget.existing!.email} (không thể thay đổi)',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                AppTextField(
                  label: 'Họ và tên',
                  controller: _fullName,
                  validator: Validators.fullName,
                  enabled: !busy,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.sm),

                if (!_isEdit) ...[
                  AppTextField(
                    label: 'Mật khẩu',
                    controller: _password,
                    obscureText: _obscurePassword,
                    validator: Validators.password,
                    enabled: !busy,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      tooltip: _obscurePassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                AppTextField(
                  label: 'Số điện thoại',
                  controller: _phone,
                  hint: 'Không bắt buộc',
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  enabled: !busy,
                ),
                const SizedBox(height: AppSpacing.sm),

                AppTextField(
                  label: 'Ảnh đại diện (URL)',
                  controller: _avatarUrl,
                  hint: 'https://… (không bắt buộc)',
                  keyboardType: TextInputType.url,
                  validator: _validateAvatarUrl,
                  enabled: !busy,
                ),
                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Ngày sinh',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickDateOfBirth,
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(
                    _dateOfBirth != null
                        ? DateFormatter.date(_dateOfBirth)
                        : 'Chọn ngày sinh (không bắt buộc)',
                  ),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                const AdminSectionHeader(title: 'Vai trò'),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final role in AdminRoles.all)
                      FilterChip(
                        label: Text(AdminRoles.label(role)),
                        selected: _roles.contains(role),
                        onSelected: busy
                            ? null
                            : (selected) => setState(() {
                                selected
                                    ? _roles.add(role)
                                    : _roles.remove(role);
                                _dirty = true;
                              }),
                      ),
                  ],
                ),
                if (_roles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      'Cần ít nhất một vai trò.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                const AdminSectionHeader(title: 'Trạng thái'),
                DropdownButtonFormField<AdminUserStatus>(
                  initialValue: _status,
                  items: [
                    for (final status in AdminUserStatus.assignable)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) => setState(() {
                          if (value != null) _status = value;
                          _dirty = true;
                        }),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AdminBottomActionBar(
          child: AppButton(
            label: _isEdit ? 'Lưu thay đổi' : 'Tạo tài khoản',
            icon: Icons.check_rounded,
            loading: busy,
            // `busy` also blocks the duplicate submit.
            onPressed: busy ? null : _submit,
          ),
        ),
      ),
    );
  }
}

/// "Discard unsaved changes?" prompt shared by the user form.
Future<bool> showAdminConfirmationDiscard(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hủy thay đổi?'),
      content: const Text('Các thay đổi chưa lưu sẽ bị mất.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Tiếp tục chỉnh sửa'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('Hủy thay đổi'),
        ),
      ],
    ),
  );
  return leave ?? false;
}
