import 'package:flutter/material.dart';

/// Sportico brand palette.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF003049);
  static const Color warmBackground = Color(0xFFFDF0D5);
  static const Color accentBlue = Color(0xFF669BBC);
  static const Color accentOrange = Color(0xFFFF6B35);

  // Derived shades
  static const Color primaryDark = Color(0xFF00243A);
  static const Color primaryLight = Color(0xFF1A4A66);
  static const Color accentBlueSoft = Color(0xFFE3EDF4);
  static const Color accentOrangeSoft = Color(0xFFFFE8DE);

  // Surfaces
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF7F3EA);
  static const Color divider = Color(0xFFE8E0CF);

  // Text
  static const Color textPrimary = Color(0xFF1B2733);
  static const Color textSecondary = Color(0xFF5C6B78);
  static const Color textOnPrimary = Colors.white;

  // Semantic
  static const Color success = Color(0xFF2E7D52);
  static const Color successSoft = Color(0xFFE0F0E7);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningSoft = Color(0xFFFCEFD9);
  static const Color danger = Color(0xFFC53030);
  static const Color dangerSoft = Color(0xFFFBE4E4);
  static const Color info = Color(0xFF2B6CB0);
  static const Color infoSoft = Color(0xFFE1ECF7);
}
