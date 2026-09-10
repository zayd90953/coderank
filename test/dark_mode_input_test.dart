import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coderank/core/design/app_theme.dart';
import 'package:coderank/features/auth/presentation/signin_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// The Scaffold may rely on the theme's `scaffoldBackgroundColor`
  /// instead of an explicit `backgroundColor`, so resolve the effective
  /// painted background for the assertion.
  Color effectiveScaffoldBg(WidgetTester tester) {
    final scaffoldFinder = find.byType(Scaffold);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    return scaffold.backgroundColor ??
        Theme.of(tester.element(scaffoldFinder)).scaffoldBackgroundColor;
  }

  group('theme adaptation — auth screens', () {
    testWidgets('sign-in email field adapts to the active theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Enter your email'),
      );
      final passwordField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Enter your password'),
      );

      for (final field in [emailField, passwordField]) {
        final style = field.style!;
        final color = style.color;
        // Input text must be light so it contrasts with the dark fill.
        expect(color, isNotNull,
            reason: 'TextField style.color should not be null');
        expect(color!.computeLuminance(), greaterThan(0.5),
            reason: 'Input text must be visible (light) in dark mode. '
                'Got ${color.toARGB32()} luminance ${color.computeLuminance()}');

        final decoration = field.decoration as InputDecoration;
        final fillColor = decoration.fillColor;
        expect(fillColor, isNotNull,
            reason: 'TextField fillColor should not be null');
        expect(fillColor!.computeLuminance(), lessThan(0.2),
            reason: 'Field fill must be dark in dark mode. '
                'Got luminance ${fillColor.computeLuminance()}');
      }
    });

    testWidgets('sign-in screen scaffold background is dark in dark mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final bg = effectiveScaffoldBg(tester);
      expect(bg.computeLuminance(), lessThan(0.2),
          reason: 'Sign-in scaffold must be dark in dark mode, not white.');
    });

    testWidgets('sign-in screen scaffold background is light in light mode',
        (tester) async {
      // The app ships light-first (default themeMode = light), so the
      // sign-in screen must be light in light mode.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const SignInScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final bg = effectiveScaffoldBg(tester);
      expect(bg.computeLuminance(), greaterThan(0.5),
          reason: 'Sign-in scaffold must be light in light mode, not black.');
    });
  });
}