import 'package:flutter/material.dart';
import '../core/theme/color_palette.dart';

class AppTheme {
  /// Build the light [ThemeData] using [palette] as the seed color.
  /// The result is rebuilt every time the active palette changes, so the
  /// entire app re-tints on `set`.
  static ThemeData buildLight(ColorPalette palette) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: palette.primary),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      );

  /// Build the dark [ThemeData] using [palette] as the seed color.
  /// Mirrors the brand colors while using dark surface colors.
  static ThemeData buildDark(ColorPalette palette) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
      );

  /// Convenience getters for the active palette — used by tests that need
  /// a `ThemeData` without re-deriving the active palette.
  static ThemeData get lightTheme =>
      buildLight(ColorPaletteController.instance.current);
  static ThemeData get darkTheme =>
      buildDark(ColorPaletteController.instance.current);
}
