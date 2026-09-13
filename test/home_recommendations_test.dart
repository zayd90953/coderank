// R-6 regression tests: recommendation-first home rework.
//
//   * "Recommended for you" section renders on Home for a fresh user
//     (momentum + daily cards) at three phone sizes without overflow.
//   * Cards are tappable and route to a real destination.
//   * Section adapts to light and dark themes.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coderank/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:coderank/features/home/presentation/home_screen.dart';
import 'package:coderank/features/practice/presentation/setup/practice_setup_screen.dart';
import 'package:coderank/shared/services/user_progress_service.dart';

Future<void> _pumpHome(WidgetTester tester, Brightness brightness) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness, colorSchemeSeed: Colors.green),
      home: const HomeScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Home — Recommended for you (R-6)', () {
    final sizes = {
      'small 320dp': const Size(320, 800),
      'regular 360dp': const Size(360, 800),
      'large 412dp': const Size(412, 915),
    };

    sizes.forEach((name, size) {
      testWidgets('renders without overflow at $name', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _pumpHome(tester, Brightness.light);

        expect(find.text('Recommended for you'), findsOneWidget);
        // Fresh user: the daily challenge is the day's anchor pick
        // (momentum is only a fallback when nothing else qualifies).
        expect(
          find.byKey(const ValueKey('recommendation_card')),
          findsOneWidget,
        );
      });
    });

    testWidgets('adapts to dark theme', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpHome(tester, Brightness.dark);

      expect(find.text('Recommended for you'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recommendation_card')),
        findsWidgets,
      );
    });

    testWidgets('daily card routes to the Daily Challenge launcher',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await _pumpHome(tester, Brightness.light);

      await tester.tap(find.byKey(const ValueKey('recommendation_card')).first);
      await tester.pumpAndSettle();

      expect(find.byType(DailyChallengeScreen), findsOneWidget);
    });

    testWidgets('momentum fallback card routes to the subject setup screen',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Complete today's daily so the engine falls through to momentum.
      final now = DateTime.now();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final seeded = UserProgressData(lastDailyChallengeDate: todayKey);
      SharedPreferences.setMockInitialValues({
        'coderank_user_progress_v1': jsonEncode(seeded.toJson()),
      });
      UserProgressService.instance.progressNotifier.value = seeded;

      await _pumpHome(tester, Brightness.light);

      expect(
        find.byKey(const ValueKey('recommendation_card')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('recommendation_card')));
      await tester.pumpAndSettle();

      expect(find.byType(PracticeSetupScreen), findsOneWidget);
    });
  });
}
