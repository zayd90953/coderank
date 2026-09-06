import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coderank/core/design/app_theme.dart';
import 'package:coderank/features/auth/presentation/signin_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('P1-5 dark mode — auth input text is visible', () {
    testWidgets('sign-in email field uses a light input color in dark mode',
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

      // Grab the email & password TextFields and assert their input style.
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

        // The fill must be dark so we do not have light-on-light.
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

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final bg = scaffold.backgroundColor;
      expect(bg, isNotNull);
      expect(bg!.computeLuminance(), lessThan(0.2),
          reason: 'Sign-in scaffold must be dark in dark mode, not white.');
    });
  });
}
