import 'package:flutter/material.dart';

import '../../../core/widgets/app_empty_state.dart';

/// Temporary target for routes whose milestone is still being built.
/// Removed once all features land — must not ship for supported features.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: AppEmptyState(
          icon: Icons.construction_rounded,
          title: 'Đang phát triển',
          message: 'Tính năng này sẽ sớm có mặt trong bản cập nhật tới.',
        ),
      ),
    );
  }
}
