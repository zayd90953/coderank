import 'package:flutter/material.dart';

/// Design-system color tokens (A-1).
///
/// These are the canonical surface/typography/status colors that every
/// screen should read. The **brand** primary color is intentionally NOT
/// here — it is a user-switchable palette preset defined in
/// `core/theme/color_palette.dart` (Brand Green / Purple / Ocean / Forest)
/// and accessed via `ColorPaletteController.instance.current.primary`.
///
/// The values below are the dark-mode defaults per the design contract
/// in `CODERANK.md` (background `#0D0D0D`, surface cards `#1A1A1A`,
/// white primary text, error `#FF4D4D`).
class AppColors {
  AppColors._();

  // ── Surfaces (dark-mode defaults) ─────────────────────────────────────
  // The app's primary visual mode is dark. Light-mode equivalents are
  // declared on ThemeData in `app_theme.dart`, not here — screens should
  // read `Theme.of(context).colorScheme.surface` so they switch
  // automatically.
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF1F1F1F);

  // ── Typography (dark-mode defaults) ────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFF0D0D0D);

  // ── Status & Feedback ──────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF0F2E22);
  static const Color error = Color(0xFFFF4D4D);
  static const Color errorLight = Color(0xFF2A0F0F);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Subject palettes (domain colors — constant across brand themes) ──
  static const Color physics = Color(0xFF38BDF8);
  static const Color physicsLight = Color(0xFF0E2A3A);
  static const Color chemistry = Color(0xFF34D399);
  static const Color chemistryLight = Color(0xFF0E2E22);
  static const Color biology = Color(0xFF14B8A6);
  static const Color biologyLight = Color(0xFF0E2E2A);

  // ── Accents (small, decorative, not brand-driven) ─────────────────────
  static const Color accent = Color(0xFFFF6B00);
  static const Color accentYellow = Color(0xFFFFB800);

  // ── Gradients ──────────────────────────────────────────────────────────
  // Brand gradients live on `ColorPalette.heroCardGradient` /
  // `accentGradient`. The ones below are domain/achievement gradients
  // that stay constant regardless of which brand preset is active.
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient physicsGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chemistryGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient biologyGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireStreakGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFFFF8C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Back-compat aliases (used by older code) ───────────────────────────
  // The pre-A-1 `AppColors.text` / `AppColors.subtitle` /
  // `AppColors.cardSurface` / `AppColors.background` constants are kept
  // as aliases pointing to the new tokens so old call sites compile
  // during the migration. Sweep targets will replace them with the
  // explicit `textPrimary` / `surface` names.
  static const Color text = textPrimary;
  static const Color subtitle = textSecondary;
  static const Color cardSurface = surface;
  static const Color backgroundLegacyLight = Color(0xFFF8F7FD);
}
