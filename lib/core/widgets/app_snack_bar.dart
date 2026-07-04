import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Feedback snackbars with a clear visual tone so users can tell success
/// from failure at a glance. Shape/behavior come from [SnackBarThemeData].
abstract final class AppSnackBar {
  static void success(BuildContext context, String message) =>
      _show(context, message, AppColors.success, Icons.check_circle_rounded);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error_rounded);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.primaryDark, Icons.info_rounded);

  static void _show(
    BuildContext context,
    String message,
    Color background,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Row(
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
