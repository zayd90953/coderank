import 'package:flutter/services.dart';

/// App-wide haptic vocabulary (A-10 motion layer).
///
/// One line per call site — the semantic name picks the platform pattern:
///   * [tick]      — selecting an option / toggling a chip (light).
///   * [success]   — a correct answer or a saved change.
///   * [error]     — a wrong answer (double-tick warning pattern).
///   * [celebrate] — results / tier-up / streak milestone (heavier).
///
/// Never throws: haptics must stay a garnish, not a crash surface.
class AppHaptics {
  AppHaptics._();

  static void tick() => _safe(() => HapticFeedback.selectionClick());
  static void success() => _safe(() => HapticFeedback.mediumImpact());
  static void error() => _safe(() => HapticFeedback.heavyImpact());
  static void celebrate() => _safe(() => HapticFeedback.heavyImpact());

  static void _safe(VoidCallback fn) {
    try {
      fn();
    } catch (_) {
      // No haptic hardware / unsupported platform — silently skip.
    }
  }
}
