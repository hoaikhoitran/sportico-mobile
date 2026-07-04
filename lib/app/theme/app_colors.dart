import 'package:flutter/material.dart';

/// Sportico color system.
///
/// **Source of truth: the Sportico web design system** (CSS custom properties).
/// Every hex value in the "web tokens" blocks below is copied verbatim from the
/// web `--color-*` variables so the mobile app stays visually consistent with
/// the web product. Do not tweak these here — change the web design system
/// first, then mirror it.
///
/// Naming follows Material 3 `ColorScheme` roles. The "legacy aliases" block at
/// the end keeps existing screens compiling while they migrate to
/// `Theme.of(context).colorScheme` / the role-named tokens above; each alias
/// points at the closest web role so the whole app adopts the new palette
/// without per-screen edits. Prefer the role-named tokens / `ColorScheme` in
/// new code.
abstract final class AppColors {
  // ===========================================================================
  // WEB TOKENS (exact hex — do not modify without updating the web system)
  // ===========================================================================

  // --- Primary ---------------------------------------------------------------
  static const Color primary = Color(0xFF3525CD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color onPrimaryContainer = Color(0xFFDAD7FF);
  static const Color inversePrimary = Color(0xFFC3C0FF);
  static const Color primaryFixed = Color(0xFFE2DFFF);
  static const Color primaryFixedDim = Color(0xFFC3C0FF);
  static const Color onPrimaryFixed = Color(0xFF0F0069);
  static const Color onPrimaryFixedVariant = Color(0xFF3323CC);

  // --- Secondary -------------------------------------------------------------
  static const Color secondary = Color(0xFF58579B);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFB6B4FF);
  static const Color onSecondaryContainer = Color(0xFF454386);

  // --- Tertiary / accent -----------------------------------------------------
  static const Color tertiary = Color(0xFF7E3000);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFA44100);
  static const Color onTertiaryContainer = Color(0xFFFFD2BE);
  static const Color tertiaryFixed = Color(0xFFFFDBCC);
  static const Color tertiaryFixedDim = Color(0xFFFFB695);

  // --- Surfaces --------------------------------------------------------------
  /// Web `--color-surface` — the app/page background.
  static const Color surfaceBackground = Color(0xFFF9F9F8);
  static const Color surfaceDim = Color(0xFFDADAD9);
  static const Color surfaceBright = Color(0xFFF9F9F8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F3);
  static const Color surfaceContainer = Color(0xFFEEEEED);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E7);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color surfaceTint = Color(0xFF4D44E3);

  // --- Text / on-surface -----------------------------------------------------
  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color inverseSurface = Color(0xFF2F3130);
  static const Color onInverseSurface = Color(0xFFF1F1F0);

  // --- Borders ---------------------------------------------------------------
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);
  static const Color borderSoft = Color(0xFFE8E8E5);

  // --- Status ----------------------------------------------------------------
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color success = Color(0xFF1F7A4D);
  static const Color successContainer = Color(0xFFD1F4DD);
  static const Color warning = Color(0xFFB95000);
  static const Color warningContainer = Color(0xFFFFE1C8);

  // ===========================================================================
  // DERIVED TOKENS (not defined by the web system — derived, with rationale)
  // ===========================================================================

  // The web system gives success/warning + their containers but no matching
  // "on-" text colors. These are derived so labels stay legible (WCAG AA):
  // white on the strong tone, and a very dark shade of the same hue on the
  // soft container.
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF00391F); // dark green (hue of #1F7A4D)
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF5A2600); // dark amber (hue of #B95000)

  // ===========================================================================
  // LEGACY ALIASES — map old names onto the web roles above. Do not add new
  // usages; migrate to the role-named tokens / ColorScheme instead.
  // ===========================================================================
  static const Color surface = surfaceContainerLowest; // cards/panels → white
  static const Color surfaceMuted = surfaceContainer; // #EEEEED
  static const Color warmBackground = surfaceBackground; // page bg #F9F9F8
  static const Color divider = borderSoft; // hairline #E8E8E5
  static const Color textPrimary = onSurface; // #1A1C1C
  static const Color textSecondary = onSurfaceVariant; // #464555
  static const Color textOnPrimary = onPrimary; // #FFFFFF
  static const Color primaryDark = onPrimaryFixed; // darkest indigo #0F0069
  static const Color primaryLight = primaryContainer; // lighter indigo #4F46E5
  static const Color accentBlue = secondary; // indigo-grey accent #58579B
  static const Color accentBlueSoft = primaryFixed; // soft indigo tint #E2DFFF
  static const Color accentOrange = tertiary; // brand accent #7E3000
  static const Color accentOrangeSoft = tertiaryFixed; // soft peach #FFDBCC
  static const Color successSoft = successContainer; // #D1F4DD
  static const Color warningSoft = warningContainer; // #FFE1C8
  static const Color danger = error; // #BA1A1A
  static const Color dangerSoft = errorContainer; // #FFDAD6
  // The web system has no dedicated "info" role → derived from the secondary
  // (indigo) family so info states read as on-brand notes.
  static const Color info = secondary; // #58579B
  static const Color infoSoft = primaryFixed; // #E2DFFF
}
