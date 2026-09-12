import 'package:flutter/material.dart';

/// Unified subject icon badge — the single visual system for rendering
/// Physics / Chemistry / Biology icons across the app (Practice Hub
/// cards, Home "Subjects" grid, Practice Setup header).
///
/// Contract:
///   * Soft 10%-opacity squircle container (radius = 30% of size) —
///     never a filled circle ("black hole") in light mode.
///   * Theme-adaptive tokens: light mode uses iOS-style 10% tints with
///     deep same-hue glyphs; dark mode uses the shared `#163020`
///     container with the light glyph ramp.
///   * Glyph color always holds WCAG AA (≥ 4.5:1) against its container
///     in both themes (contrast ratios verified per token pair below).
///
/// Standardized geometry (list view and grid view use the same ratios):
///   container radius 30% of size · glyph 50% of size · squircle shape.
class SubjectIconBadge extends StatelessWidget {
  final String subject;
  final double size;

  const SubjectIconBadge({
    super.key,
    required this.subject,
    this.size = 44,
  });

  // ── Token table ────────────────────────────────────────────────────────
  // Container hexes are exactly as specified (light = 10% alpha over the
  // base hue; dark = shared #163020). Light glyph hexes are deepened
  // within the same hue family to hold WCAG AA ≥ 4.5:1 against the 10%
  // tint COMPOSITED over the worst-case light card surface (pure white
  // and the light theme's tone-96 surfaceContainer); dark glyphs are
  // exactly as specified.

  /// Physics — light glyph #0862C4 (spec #007AFF family deepened;
  /// ≥4.55:1 on every light surface), dark glyph #60A5FA on #163020
  /// (5.6:1).
  static const Color physicsGlyphLight = Color(0xFF0862C4);
  static const Color physicsGlyphDark = Color(0xFF60A5FA);
  static const Color physicsBase = Color(0xFF007AFF);

  /// Chemistry — light glyph #A94E08 (spec amber #F59E0B family deepened
  /// to ≥4.5:1; the raw spec glyph was ~2.0:1), dark glyph #FBBF24
  /// (8.5:1).
  static const Color chemistryGlyphLight = Color(0xFFA94E08);
  static const Color chemistryGlyphDark = Color(0xFFFBBF24);
  static const Color chemistryBase = Color(0xFFF59E0B);

  /// Biology — light glyph #036B4E (spec emerald #10B981 family deepened
  /// to ≥5.2:1), dark glyph #34D399 (7.4:1).
  static const Color biologyGlyphLight = Color(0xFF036B4E);
  static const Color biologyGlyphDark = Color(0xFF34D399);
  static const Color biologyBase = Color(0xFF10B981);

  /// Dark-mode container — shared by all three subjects per spec.
  static const Color darkContainer = Color(0xFF163020);

  /// Resolves the glyph color for [subject] under the ambient theme.
  static Color glyphOf(String subject, Brightness brightness) {
    final light = brightness == Brightness.light;
    switch (_kindOf(subject)) {
      case _SubjectKind.physics:
        return light ? physicsGlyphLight : physicsGlyphDark;
      case _SubjectKind.chemistry:
        return light ? chemistryGlyphLight : chemistryGlyphDark;
      case _SubjectKind.biology:
        return light ? biologyGlyphLight : biologyGlyphDark;
    }
  }

  /// Resolves the container color for [subject] under the ambient theme.
  static Color containerOf(String subject, Brightness brightness) {
    if (brightness == Brightness.dark) return darkContainer;
    switch (_kindOf(subject)) {
      case _SubjectKind.physics:
        return physicsBase.withValues(alpha: 0.10);
      case _SubjectKind.chemistry:
        return chemistryBase.withValues(alpha: 0.10);
      case _SubjectKind.biology:
        return biologyBase.withValues(alpha: 0.10);
    }
  }

  static IconData _iconOf(_SubjectKind kind) {
    switch (kind) {
      case _SubjectKind.physics:
        return Icons.bolt_rounded;
      case _SubjectKind.chemistry:
        return Icons.science_rounded;
      case _SubjectKind.biology:
        return Icons.biotech_rounded;
    }
  }

  static _SubjectKind _kindOf(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('chem')) return _SubjectKind.chemistry;
    if (s.contains('bio')) return _SubjectKind.biology;
    return _SubjectKind.physics;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final glyph = glyphOf(subject, brightness);
    final container = containerOf(subject, brightness);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: Icon(
        _iconOf(_kindOf(subject)),
        color: glyph,
        size: size * 0.50,
      ),
    );
  }
}

enum _SubjectKind { physics, chemistry, biology }
