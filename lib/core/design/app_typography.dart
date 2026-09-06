import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design-system typography (A-1).
///
/// Two fonts per the design contract in `CODERANK.md`:
///   * **Nunito** (rounded, personality-forward) for display, headlines,
///     scores, and any moment that should feel "game-like".
///   * **Inter** (clean, highly legible) for body text, question
///     content, and anything read under time pressure.
///
/// Bundled via `google_fonts` so the font files are loaded at runtime
/// from the Google Fonts CDN (cached after first run). If the device
/// is offline on first launch, `google_fonts` falls back to the system
/// font — the app still renders cleanly, just with the default font.
class AppTypography {
  AppTypography._();

  // ── Font families ──────────────────────────────────────────────────────
  static TextStyle _nunito({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ── Display / headline (Nunito) ───────────────────────────────────────
  /// Big numbers and "level up" moments. The personality-forward choice.
  static TextStyle display({Color? color}) => _nunito(
        size: 36,
        weight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: color,
      );

  /// Section titles, screen titles.
  static TextStyle headline({Color? color}) => _nunito(
        size: 24,
        weight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.3,
        color: color,
      );

  /// Card titles, prominent labels.
  static TextStyle title({Color? color}) => _nunito(
        size: 17,
        weight: FontWeight.w700,
        height: 1.25,
        color: color,
      );

  // ── Body (Inter) ──────────────────────────────────────────────────────
  /// Default body text. Used for everything that isn't display/headline.
  static TextStyle body({Color? color}) => _inter(
        size: 14,
        weight: FontWeight.w500,
        height: 1.4,
        color: color,
      );

  /// Smaller body / supporting text.
  static TextStyle bodySmall({Color? color}) => _inter(
        size: 12,
        weight: FontWeight.w500,
        height: 1.35,
        color: color,
      );

  /// Caption / fine print.
  static TextStyle caption({Color? color}) => _inter(
        size: 11,
        weight: FontWeight.w500,
        height: 1.3,
        color: color,
      );

  // ── Specialized ───────────────────────────────────────────────────────
  /// Button labels. Nunito for the game-like punch.
  static TextStyle button({Color? color}) => _nunito(
        size: 15,
        weight: FontWeight.w700,
        letterSpacing: 0.2,
        color: color,
      );

  /// Big stats / numbers (XP, accuracy %, rank).
  static TextStyle statNumber({Color? color}) => _nunito(
        size: 28,
        weight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -0.5,
        color: color,
      );

  /// Stat labels (the "Questions" / "Accuracy" text under a number).
  static TextStyle statLabel({Color? color}) => _inter(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      );

  // ── Material TextTheme ────────────────────────────────────────────────
  /// Build a full [TextTheme] wired to the two fonts. Pass to
  /// [ThemeData.textTheme]. The default `color` resolves against the
  /// theme's `colorScheme.onSurface` at use time, so light/dark mode
  /// flows through automatically.
  static TextTheme textTheme(Color textColor) {
    return TextTheme(
      displayLarge: display(color: textColor),
      displayMedium: display(color: textColor),
      displaySmall: headline(color: textColor),
      headlineLarge: headline(color: textColor),
      headlineMedium: headline(color: textColor),
      headlineSmall: title(color: textColor),
      titleLarge: title(color: textColor),
      titleMedium: title(color: textColor),
      titleSmall: _nunito(
        size: 14,
        weight: FontWeight.w700,
        color: textColor,
      ),
      bodyLarge: body(color: textColor),
      bodyMedium: body(color: textColor),
      bodySmall: bodySmall(color: textColor),
      labelLarge: button(color: textColor),
      labelMedium: caption(color: textColor),
      labelSmall: caption(color: textColor),
    );
  }
}
