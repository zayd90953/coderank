import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Design-system [ThemeData] factories (A-1).
///
/// `buildDark` is the default per the design contract. `buildLight` is
/// retained for the existing user-toggle (Theme picker in Profile).
/// Both themes are rebuilt every time the active [ColorPalette] changes,
/// so the entire app re-tints on `set` without a restart.
class AppTheme {
  AppTheme._();

  /// Dark theme — primary visual mode for CodeRank.
  static ThemeData buildDark(ColorPalette palette) {
    final base = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base.copyWith(
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        primary: palette.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: palette.primary,
        onSecondary: AppColors.textOnPrimary,
        error: AppColors.error,
        onError: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headline(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      textTheme: AppTypography.textTheme(AppColors.textPrimary),
      primaryTextTheme: AppTypography.textTheme(AppColors.textOnPrimary),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        hintStyle: AppTypography.body(color: AppColors.textMuted),
        labelStyle: AppTypography.bodySmall(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          textStyle: AppTypography.button(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppTypography.button(color: AppColors.textPrimary),
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: AppTypography.button(color: palette.primary),
        ),
      ),
    );
  }

  /// Light theme — retained for the Theme picker, but the design
  /// contract is dark-first. Uses the same typography and a brand-seeded
  /// [ColorScheme].
  static ThemeData buildLight(ColorPalette palette) {
    final base = ColorScheme.fromSeed(seedColor: palette.primary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: base.copyWith(
        primary: palette.primary,
        onPrimary: Colors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: const Color(0xFFEDE8F5),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headline(color: AppColors.text),
      ),
      textTheme: AppTypography.textTheme(AppColors.text),
      primaryTextTheme: AppTypography.textTheme(Colors.white),
      iconTheme: const IconThemeData(color: AppColors.text),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: AppTypography.button(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// Convenience getters for callers that need a `ThemeData` without
  /// re-deriving the active palette.
  static ThemeData get darkTheme =>
      buildDark(ColorPaletteController.instance.current);
  static ThemeData get lightTheme =>
      buildLight(ColorPaletteController.instance.current);
}
