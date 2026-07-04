/// 4-pt spacing scale used across the app.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Default horizontal screen padding.
  static const double screenH = 16;

  /// Corner radii (existing scale — kept for backwards compatibility).
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusPill = 999;

  // Web-aligned corner radii (source of truth: web design system `--radius-*`).
  // Applied in [AppTheme] for the components it themes; use these for new UI.
  static const double radiusXs = 4; // --radius-xs
  static const double radiusControl = 6; // small controls, --radius-sm
  static const double radiusField = 10; // inputs, --radius-lg
  static const double radiusCard = 12; // cards/sheets, --radius-xl
  static const double radiusFull = 999; // pills/chips, --radius-full
}
