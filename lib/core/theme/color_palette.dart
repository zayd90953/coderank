import 'package:flutter/material.dart';
import '../../shared/services/user_preferences_service.dart';

/// The single brand color preset for CodeRank.
///
/// Only [brandGreen] exists. Subject colors (Physics / Chemistry / Biology)
/// and achievement colors (gold, fire) are NOT modeled here — they are
/// domain colors that stay constant regardless of the brand preset.
class ColorPalette {
  /// Stable identifier. Currently always `'green'`.
  final String id;

  /// Human-readable label, e.g. `'Electric Green'`.
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

  /// Electric Green — the CodeRank brand accent (per CODERANK.md).
  /// The only active preset; all others have been removed.
  static const ColorPalette brandGreen = ColorPalette(
    id: 'green',
    label: 'Electric Green',
    primary: Color(0xFF39D353),
    primarySubtle: Color(0xFFD1FAE5),
    heroCardGradient: LinearGradient(
      colors: [Color(0xFF1F8A35), Color(0xFF39D353), Color(0xFF6BE381)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFF1F8A35), Color(0xFF39D353)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// All selectable presets. Only [brandGreen] remains — the color picker
  /// has been removed per the user's request.
  static const List<ColorPalette> all = [brandGreen];

  /// Look up a palette by its persisted id. Falls back to
  /// [brandGreen] for any unknown / future id, so a corrupted or
  /// older pref value can never break the app.
  static ColorPalette byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return brandGreen;
  }
}

/// App-wide controller for the active [ColorPalette].
///
/// Mirrors the singleton + [ValueNotifier] pattern used by
/// [UserPreferencesService] and [UserProgressService]:
///   * One instance per app lifetime.
///   * `paletteNotifier` fires on every change so widgets can rebuild
///     via [ValueListenableBuilder] / [ListenableBuilder].
///   * `set(...)` is a no-op (only one preset remains).
///
/// The `MaterialApp` is wired to listen to this notifier in
/// `lib/app/app.dart`, so the entire app re-tints on `set` without a
/// restart.
class ColorPaletteController {
  ColorPaletteController._();
  static final ColorPaletteController instance = ColorPaletteController._();

  final ValueNotifier<ColorPalette> paletteNotifier =
      ValueNotifier<ColorPalette>(ColorPalette.brandGreen);

  ColorPalette get current => paletteNotifier.value;

  /// Persist a new palette id and notify listeners. Returns the
  /// resolved [ColorPalette] (so callers can use the typed object).
  /// Since only [brandGreen] remains, this is now a no-op that always
  /// returns [brandGreen]. Kept for forward-compatibility.
  Future<ColorPalette> set(String id) async {
    paletteNotifier.value = ColorPalette.brandGreen;
    return ColorPalette.brandGreen;
  }

  /// Re-read the persisted id (e.g. after [UserPreferencesService] has
  /// finished bootstrapping from disk on app launch) and update the
  /// notifier if it differs. Idempotent. Only [brandGreen] exists now.
  void hydrateFromPrefs() {
    paletteNotifier.value = ColorPalette.brandGreen;
  }
}
