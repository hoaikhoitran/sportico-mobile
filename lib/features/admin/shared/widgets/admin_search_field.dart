import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Debounced keyword search — one request per pause in typing, not per keypress.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onSearch,
    this.debounce = const Duration(milliseconds: 400),
  });

  final String hint;
  final ValueChanged<String> onSearch;
  final Duration debounce;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      if (mounted) widget.onSearch(value.trim());
    });
  }

  void _clear() {
    _debounceTimer?.cancel();
    _controller.clear();
    widget.onSearch('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        _onChanged(value);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Xóa tìm kiếm',
              ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
