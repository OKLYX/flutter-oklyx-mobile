import 'package:flutter/material.dart';

/// Central brand color palette for the OKLYX mobile app.
///
/// **Purpose**: Single source of truth for colors, mirroring the Next.js
/// frontend design tokens so web and mobile stay visually consistent.
/// **Rule**: Never hardcode brand HEX values (e.g. `Color(0xffFEC416)`) in
/// pages/widgets. Always reference these constants instead.
/// **File**: lib/shared/themes/app_colors.dart
///
/// Token reference (matches frontend CSS variables):
/// - brandMain        #FEC416  primary action (buttons, focus ring, logo)
/// - brandMainHover   #E0AC13  primary action hover/pressed
/// - brandMainLight   #FED44F  light variant
/// - brandGreen       #14A05D  confirm / positive action
/// - brandGreenHover  #0F804A  positive action hover/pressed
/// - brandTeal        #0A7E7D  teal accent
/// - brandSlate       #263238  slate accent / dark text
///
/// Status tokens (fixed-meaning badge/alert tints, mirrors the web palette):
/// - infoSurface/infoForeground        blue-50  / blue-700
/// - successSurface/successForeground  green-100 / green-700
/// - warningSurface/warningForeground  amber-50 / amber-800
///
/// ⚠️ Yellow is a light color: text/icons placed on `brandMain` must use a
/// dark foreground (`foregroundLight` / `brandSlate`), not white.
/// ⚠️ Neutral surfaces/text/borders are NOT tokens here: read them from
/// `Theme.of(context).colorScheme` (`surface`, `onSurface`,
/// `onSurfaceVariant`, `outlineVariant`, `surfaceContainerHighest`) so they
/// follow light/dark mode.
class AppColors {
  AppColors._();

  // --- Brand palette ---
  static const Color brandMain = Color(0xFFFEC416);
  static const Color brandMainHover = Color(0xFFE0AC13);
  static const Color brandMainLight = Color(0xFFFED44F);
  static const Color brandGreen = Color(0xFF14A05D);
  static const Color brandGreenHover = Color(0xFF0F804A);
  static const Color brandTeal = Color(0xFF0A7E7D);
  static const Color brandSlate = Color(0xFF263238);

  // --- Surfaces (Light) ---
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color foregroundLight = Color(0xFF171717);
  static const Color pageBackgroundLight = Color(0xFFF9FAFB);

  // --- Surfaces (Dark) ---
  static const Color backgroundDark = Color(0xFF292929);
  static const Color foregroundDark = Color(0xFFE5E5E5);
  static const Color pageBackgroundDark = Color(0xFF303030);

  // --- Semantic status tints (badges / soft alert surfaces) ---
  // Fixed-meaning colors that no ColorScheme slot covers. Values mirror the
  // web palette (soft -50/-100 surface + -700/-800 text) so a status badge
  // reads the same on both platforms.
  // ⚠️ Error/danger states do NOT live here: use
  // `colorScheme.error` / `errorContainer` / `onErrorContainer` instead.
  static const Color infoSurface = Color(0xFFEFF6FF); // blue-50
  static const Color infoForeground = Color(0xFF1D4ED8); // blue-700
  static const Color successSurface = Color(0xFFDCFCE7); // green-100
  static const Color successForeground = Color(0xFF15803D); // green-700
  static const Color warningSurface = Color(0xFFFFFBEB); // amber-50
  static const Color warningForeground = Color(0xFF92400E); // amber-800
}
