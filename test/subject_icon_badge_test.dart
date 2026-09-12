import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coderank/shared/widgets/subject_icon_badge.dart';

/// Regression tests for the unified subject icon badge system:
///   * container tokens match the spec exactly (10% tints light /
///     #163020 dark),
///   * glyph colors hold WCAG AA (≥ 4.5:1) against their containers in
///     BOTH themes — re-computed here so a future token tweak that
///     breaks contrast fails this test.
void main() {
  group('token contract', () {
    test('dark container is the shared #163020 for every subject', () {
      for (final subject in ['Physics', 'Chemistry', 'Biology']) {
        expect(
          SubjectIconBadge.containerOf(subject, Brightness.dark),
          const Color(0xFF163020),
          reason: '$subject dark container must be #163020',
        );
      }
    });

    test('light containers are 10% alpha of the spec base hues', () {
      Color tint(Color base) => base.withValues(alpha: 0.10);

      expect(
        SubjectIconBadge.containerOf('Physics', Brightness.light),
        tint(SubjectIconBadge.physicsBase),
      );
      expect(
        SubjectIconBadge.containerOf('Chemistry', Brightness.light),
        tint(SubjectIconBadge.chemistryBase),
      );
      expect(
        SubjectIconBadge.containerOf('Biology', Brightness.light),
        tint(SubjectIconBadge.biologyBase),
      );
      // And the bases are exactly the spec hexes.
      expect(SubjectIconBadge.physicsBase, const Color(0xFF007AFF));
      expect(SubjectIconBadge.chemistryBase, const Color(0xFFF59E0B));
      expect(SubjectIconBadge.biologyBase, const Color(0xFF10B981));
    });

    test('dark glyph hexes are exactly as specified', () {
      expect(
        SubjectIconBadge.glyphOf('Physics', Brightness.dark),
        const Color(0xFF60A5FA),
      );
      expect(
        SubjectIconBadge.glyphOf('Chemistry', Brightness.dark),
        const Color(0xFFFBBF24),
      );
      expect(
        SubjectIconBadge.glyphOf('Biology', Brightness.dark),
        const Color(0xFF34D399),
      );
    });
  });  group('WCAG AA contrast (≥ 4.5:1)', () {
    // The light container is a 10% alpha tint — it must be composited
    // over the surface it actually renders on before contrast is
    // measured. Worst-case light surfaces: pure white (scaffold) and
    // the light theme's surfaceContainer (~tone 96). Dark containers
    // are opaque, so they measure directly.
    Color compositeOver(Color tint, Color surface) {
      final a = tint.a;
      return Color.fromARGB(
        255,
        ((tint.r * a + surface.r * (1 - a)) * 255).round(),
        ((tint.g * a + surface.g * (1 - a)) * 255).round(),
        ((tint.b * a + surface.b * (1 - a)) * 255).round(),
      );
    }

    const lightSurfaces = [Color(0xFFFFFFFF), Color(0xFFF1EFE9)];

    double contrastRatio(Color fg, Color bg) {
      final l1 = fg.computeLuminance();
      final l2 = bg.computeLuminance();
      final hi = l1 > l2 ? l1 : l2;
      final lo = l1 > l2 ? l2 : l1;
      return (hi + 0.05) / (lo + 0.05);
    }

    test('light glyphs meet AA over every worst-case light surface', () {
      for (final subject in ['Physics', 'Chemistry', 'Biology']) {
        final glyph = SubjectIconBadge.glyphOf(subject, Brightness.light);
        final tint = SubjectIconBadge.containerOf(subject, Brightness.light);
        for (final surface in lightSurfaces) {
          final container = compositeOver(tint, surface);
          final ratio = contrastRatio(glyph, container);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$subject light glyph ${glyph.toARGB32()} on tint-over-'
                '${surface.toARGB32()} = ${ratio.toStringAsFixed(2)}:1 '
                '(WCAG AA requires ≥ 4.5:1)',
          );
        }
      }
    });

    test('dark glyphs meet AA against the opaque dark container', () {
      for (final subject in ['Physics', 'Chemistry', 'Biology']) {
        final glyph = SubjectIconBadge.glyphOf(subject, Brightness.dark);
        final container =
            SubjectIconBadge.containerOf(subject, Brightness.dark);
        final ratio = contrastRatio(glyph, container);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '$subject dark glyph ${glyph.toARGB32()} on '
              '${container.toARGB32()} = ${ratio.toStringAsFixed(2)}:1 '
              '(WCAG AA requires ≥ 4.5:1)',
        );
      }
    });
  });

  group('widget rendering', () {
    Widget host(String subject, Brightness brightness) => MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: Center(
              child: SubjectIconBadge(subject: subject, size: 44),
            ),
          ),
        );

    testWidgets('renders the right glyph per subject at 50% scale',
        (tester) async {
      final expected = {
        'Physics': Icons.bolt_rounded,
        'Chemistry': Icons.science_rounded,
        'Biology': Icons.biotech_rounded,
      };
      final subjects = expected.entries.toList();
      for (final entry in subjects) {
        await tester.pumpWidget(host(entry.key, Brightness.light));
        final iconWidget = tester.widget<Icon>(find.byIcon(entry.value));
        expect(iconWidget.size, 22); // 50% of 44
        expect(
          iconWidget.color,
          SubjectIconBadge.glyphOf(entry.key, Brightness.light),
        );
      }
    });

    testWidgets('container is a squircle (radius = 30% of size), never a circle',
        (tester) async {
      await tester.pumpWidget(host('Physics', Brightness.light));
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.shape, isNot(BoxShape.circle));
      expect(
        (decoration.borderRadius as BorderRadius).topLeft.x,
        closeTo(44 * 0.30, 0.001),
      );
      // Light mode: 10% tint container, not an opaque dark fill.
      expect(decoration.color!.a, closeTo(0.10, 0.001));
    });

    testWidgets('adapts to dark theme tokens', (tester) async {
      await tester.pumpWidget(host('Chemistry', Brightness.dark));
      final iconWidget =
          tester.widget<Icon>(find.byIcon(Icons.science_rounded));
      expect(iconWidget.color, const Color(0xFFFBBF24));
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        const Color(0xFF163020),
      );
    });
  });
}
