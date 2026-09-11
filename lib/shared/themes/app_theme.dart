import 'package:flutter/material.dart';

import 'app_colors.dart';

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
    );

    return _base(
      colorScheme,
      scaffoldBackground: AppColors.pageBackgroundLight,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.foregroundLight,
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandMain,
          foregroundColor: AppColors.foregroundLight,
        ),
      ),
      // Confirm / positive actions use brand green.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          foregroundColor: Colors.white,
        ),
      ),
      // Brand yellow as text on light surfaces has poor contrast; use a dark
      // label so text buttons stay legible.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onSurface,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
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
