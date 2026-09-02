import 'package:flutter/material.dart';
import '../../shared/services/user_preferences_service.dart';

/// A user-selectable brand color preset.
///
/// The app supports three presets today; this is intentionally a small
/// enumeration so we can ship a fast, focused "color theme" picker without
/// becoming a theming system. Subject colors (Physics / Chemistry / Biology)
/// and achievement colors (gold, fire) are NOT modeled here — they are
/// domain colors that should stay constant regardless of which brand preset
/// the student picks.
class ColorPalette {
  /// Stable identifier persisted in [UserPreferencesService].
  /// One of `'purple'` / `'ocean'` / `'forest'`.
  final String id;

  /// Human-readable label, e.g. `'Brand Purple'`.
  final String label;

  /// The seed/brand color used for `ColorScheme.fromSeed` and direct
  /// reads (button backgrounds, icon tints, etc.).
  final Color primary;

  /// A pastel "subtle" variant of [primary] — used for chip backgrounds,
  /// soft tints, and avatar picker fallbacks.
  final Color primarySubtle;

  /// A 3-stop diagonal gradient used for hero cards, avatar rings, and
  /// other prominent surface fills.
  final LinearGradient heroCardGradient;

  /// A 2-stop diagonal gradient used for primary buttons and
  /// progress rings.
  final LinearGradient accentGradient;

  const ColorPalette({
    required this.id,
    required this.label,
    required this.primary,
    required this.primarySubtle,
    required this.heroCardGradient,
    required this.accentGradient,
  });

  // ── Presets ───────────────────────────────────────────────────────────

  /// The default CodeRank brand purple. Matches the colors used in the
  /// existing onboarding / marketing screens.
  static const ColorPalette brandPurple = ColorPalette(
    id: 'purple',
    label: 'Brand Purple',
    primary: Color(0xFF5F00FF),
    primarySubtle: Color(0xFFF3EDFF),
    heroCardGradient: LinearGradient(
      colors: [Color(0xFF4A00D4), Color(0xFF7312FF), Color(0xFF913FFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF5F00FF), Color(0xFF8B35FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Cool sky / ocean blue — for students who prefer a calmer, academic
  /// feel over the energetic purple.
  static const ColorPalette oceanBlue = ColorPalette(
    id: 'ocean',
    label: 'Ocean Blue',
    primary: Color(0xFF0EA5E9),
    primarySubtle: Color(0xFFE0F2FE),
    heroCardGradient: LinearGradient(
      colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Forest green — for students who prefer a grounded, study-focused
  /// aesthetic.
  static const ColorPalette forestGreen = ColorPalette(
    id: 'forest',
    label: 'Forest Green',
    primary: Color(0xFF10B981),
    primarySubtle: Color(0xFFD1FAE5),
    heroCardGradient: LinearGradient(
      colors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF34D399)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF059669), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// All selectable presets, in display order. Drives the color picker.
  static const List<ColorPalette> all = [brandPurple, oceanBlue, forestGreen];

  /// Look up a palette by its persisted id. Falls back to
  /// [brandPurple] for any unknown / future id, so a corrupted or
  /// older pref value can never break the app.
  static ColorPalette byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return brandPurple;
  }
}

/// App-wide controller for the active [ColorPalette].
///
/// Mirrors the singleton + [ValueNotifier] pattern used by
/// [UserPreferencesService] and [UserProgressService]:
///   * One instance per app lifetime.
///   * `paletteNotifier` fires on every change so widgets can rebuild
///     via [ValueListenableBuilder] / [ListenableBuilder].
///   * `set(...)` writes through to [UserPreferencesService] so the
///     choice survives a relaunch.
///
/// The `MaterialApp` is wired to listen to this notifier in
/// `lib/app/app.dart`, so the entire app re-tints on `set` without a
/// restart.
class ColorPaletteController {
  ColorPaletteController._();
  static final ColorPaletteController instance = ColorPaletteController._();

  final ValueNotifier<ColorPalette> paletteNotifier =
      ValueNotifier<ColorPalette>(ColorPalette.brandPurple);

  ColorPalette get current => paletteNotifier.value;

  /// Persist a new palette id and notify listeners. Returns the
  /// resolved [ColorPalette] (so callers can use the typed object).
  Future<ColorPalette> set(String id) async {
    final next = ColorPalette.byId(id);
    paletteNotifier.value = next;
    await UserPreferencesService.instance.setColorThemeId(id);
    return next;
  }

  /// Re-read the persisted id (e.g. after [UserPreferencesService] has
  /// finished bootstrapping from disk on app launch) and update the
  /// notifier if it differs. Idempotent.
  void hydrateFromPrefs() {
    final id = UserPreferencesService.instance.current.colorThemeId;
    final next = ColorPalette.byId(id);
    if (next.id != paletteNotifier.value.id) {
      paletteNotifier.value = next;
    }
  }
}
