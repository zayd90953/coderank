import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coderank/features/navigation/main_nav_screen.dart';

void main() {
  setUp(() {
    // UserProgressService persists via SharedPreferences; keep it hermetic.
    SharedPreferences.setMockInitialValues({});
  });

  group('MainNavScreen — bottom navigation bar stays present (P1-4)', () {
    testWidgets('bottom bar renders with all three destinations',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainNavScreen()),
      );
      await tester.pumpAndSettle();

      // Each _NavItem is keyed; all three must be present regardless of the
      // IndexedStack keeping tab bodies mounted. The leaderboard tab
      // (nav_rank) was removed in the launch UI cleanup.
      for (final keyName in const [
        'nav_home',
        'nav_practice',
        'nav_analytics',
      ]) {
        expect(
          find.byKey(ValueKey(keyName)),
          findsOneWidget,
          reason: 'Bottom nav must include the $keyName destination',
        );
      }
      expect(
        find.byKey(const ValueKey('nav_rank')),
        findsNothing,
        reason: 'Leaderboard tab must not exist',
      );
    });

    testWidgets('switching tabs keeps every destination in the bar',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainNavScreen()),
      );
      await tester.pumpAndSettle();

      const destinationKeys = [
        ValueKey('nav_practice'),
        ValueKey('nav_analytics'),
        ValueKey('nav_home'),
      ];

      for (final key in destinationKeys) {
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();

        // After switching, all three destinations are still in the bar.
        for (final k in destinationKeys) {
          expect(find.byKey(k), findsOneWidget,
              reason: 'Destination $k must remain after tapping $key');
        }
      }
    });

    testWidgets('home tab is the initial tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainNavScreen()),
      );
      await tester.pumpAndSettle();

      // 'Your Progress' is HomeScreen content, proving Home tab is active.
      expect(find.text('Your Progress'), findsOneWidget);
    });
  });
}
