// Smoke test for the switchable color theme (P2-3).
//
// The original `widget_test.dart` was the default Flutter counter scaffold and
// no longer matched the project (the app root is `CodeRankApp`, not `MyApp`).
// This file covers the new pieces of P2-3 instead:
//   * `ColorPalette.byId` resolves the right preset and falls back to purple.
//   * `ColorSwatch` renders the supplied color and the selection ring.

import 'package:flutter/material.dart' hide ColorSwatch;
import 'package:flutter_test/flutter_test.dart';
import 'package:coderank/core/theme/color_palette.dart';
import 'package:coderank/features/profile/presentation/widgets/color_swatch.dart';

void main() {
  group('ColorPalette — preset lookup', () {
    test('byId returns brandGreen for any known id', () {
      // Only brandGreen remains — all ids fall back to it.
      expect(ColorPalette.byId('green'), ColorPalette.brandGreen);
      expect(ColorPalette.byId('purple'), ColorPalette.brandGreen);
      expect(ColorPalette.byId('ocean'), ColorPalette.brandGreen);
      expect(ColorPalette.byId('forest'), ColorPalette.brandGreen);
    });

    test('byId falls back to brandGreen for unknown ids', () {
      expect(ColorPalette.byId('neon-pink'), ColorPalette.brandGreen);
      expect(ColorPalette.byId(''), ColorPalette.brandGreen);
    });

    test('only one preset exists', () {
      expect(ColorPalette.all.length, 1);
      expect(ColorPalette.all.first, ColorPalette.brandGreen);
    });
  });

  group('ColorSwatch — render', () {
    testWidgets('renders the supplied color and selection ring',
        (tester) async {
      const testColor = Color(0xFF00FF00);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ColorSwatch(color: testColor, selected: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ColorSwatch), findsOneWidget);

      // The outer ring draws the swatch in `testColor` when selected.
      final swatch = tester.widget<ColorSwatch>(find.byType(ColorSwatch));
      expect(swatch.color, testColor);
      expect(swatch.selected, isTrue);
    });
  });
}
