import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Application ThemeData built from [AppColors].
///
/// **Purpose**: Wires the brand palette into Material 3 so widgets that read
/// from the theme (buttons, focus rings, app bar, nav bar) automatically use
/// brand colors. Mirrors the frontend's light/dark surface tokens.
/// **Usage**: `MaterialApp.router(theme: AppTheme.light, darkTheme: AppTheme.dark, ...)`
/// **File**: lib/shared/themes/app_theme.dart
///
/// ⚠️ Default mode is still light (`main.dart`). Pages no longer hardcode
/// `Colors.*` — they read `colorScheme` / `AppColors` — so `darkTheme` is now
/// reachable; flip `themeMode` to `ThemeMode.system` in a separate change once
/// every screen has been reviewed under the dark palette.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandMain,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.brandMain,
      // Yellow primary needs dark text/icons on top.
      onPrimary: AppColors.foregroundLight,
      secondary: AppColors.brandGreen,
      onSecondary: Colors.white,
      tertiary: AppColors.brandTeal,
      onTertiary: Colors.white,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.foregroundLight,
      // Neutral slots use the web grays instead of colors derived from the
      // yellow seed (FEATURE_2610_03 · D137).
      onSurfaceVariant: AppColors.gray500,
      outline: AppColors.gray300,
      outlineVariant: AppColors.gray200,
      surfaceContainerLowest: AppColors.backgroundLight,
      surfaceContainerLow: AppColors.gray50,
      surfaceContainer: AppColors.gray100,
      surfaceContainerHigh: AppColors.gray100,
      surfaceContainerHighest: AppColors.gray100,
      surfaceTint: Colors.transparent,
    );

    return _base(
      colorScheme,
      // Flat cards are white on a darker page so the areas stand apart
      // (D129 ④).
      scaffoldBackground: kAppCardStyle == AppCardStyle.flat
          ? AppColors.gray100
          : AppColors.pageBackgroundLight,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.foregroundLight,
    ).copyWith(
      // Dialogs, center popups and popup menus are white like the web (D137).
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.backgroundLight,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.backgroundLight,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandMain,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.brandMain,
      onPrimary: AppColors.brandSlate,
      secondary: AppColors.brandGreen,
      onSecondary: Colors.white,
      tertiary: AppColors.brandTeal,
      onTertiary: Colors.white,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.foregroundDark,
    );

    return _base(
      colorScheme,
      scaffoldBackground: AppColors.pageBackgroundDark,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.foregroundDark,
    );
  }

  static ThemeData _base(
    ColorScheme colorScheme, {
    required Color scaffoldBackground,
    required Color surface,
    required Color onSurface,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      // Cards use the plain surface color (white in light mode) like the web
      // cards. Without this the Material 3 default (`surfaceContainerLow`)
      // tints every card: gray in light mode, derived from the yellow seed in
      // dark mode.
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      // One filled button for the whole app: brand yellow with a dark label
      // (FEATURE_2610_02 · N11). Green is written at the call site only for
      // the buttons listed in D101; red delete buttons keep their own color.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandMain,
          foregroundColor: AppColors.foregroundLight,
        ),
      ),
      // Brand yellow as text on light surfaces has poor contrast; use a dark
      // label so text buttons stay legible.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onSurface,
        ),
      ),
      // Every input: outline border on all sides + dense height
      // (FEATURE_2610_02 · N12). Pages do not write a border or `isDense`.
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        isDense: true,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.brandMain, width: 2),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.brandMain,
        unselectedItemColor: onSurface.withValues(alpha: 0.6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandMain,
      ),
    );
  }
}
