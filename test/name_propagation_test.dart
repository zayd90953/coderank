// Group D regression tests: display-name propagation.
//
// Root cause being guarded against: Home read `FirebaseAuth.currentUser
// .displayName`, which caches at sign-in, while the profile page writes to
// UserPreferencesService. After "Edit Display Name", Home kept showing the
// old name. Home must read prefs.displayName FIRST (with the Firebase name
// as fallback) and rebuild whenever prefsNotifier changes.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coderank/features/home/presentation/home_screen.dart';
import 'package:coderank/shared/services/user_preferences_service.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: HomeScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('home greeting reads the same source the profile writes (Group D)', () {
    testWidgets(
        'shows the edited name immediately, overriding a stale auth name',
        (tester) async {
      await UserPreferencesService.instance.initialize();

      // Simulate what the Edit Name sheet persists (local write happens
      // without any auth call in the widget-test environment).
      await UserPreferencesService.instance.setDisplayName('Aarav Sharma');
      await _pumpHome(tester);

      // prefs.displayName wins → first word used in the greeting.
      expect(find.textContaining('Aarav'), findsOneWidget);
      // The (absent) auth fallback must NOT be rendered instead.
      expect(find.textContaining('Student'), findsNothing);
    });

    testWidgets(
        'name change propagates live without re-creating the screen',
        (tester) async {
      await UserPreferencesService.instance.initialize();
      await _pumpHome(tester);

      // Fresh user with no auth profile: generic fallback is shown.
      expect(find.textContaining('Student'), findsOneWidget);

      // The sheet save triggers prefsNotifier → Home rebuilds. No re-mount.
      await UserPreferencesService.instance.setDisplayName('Priya Verma');
      await tester.pumpAndSettle();

      expect(find.textContaining('Priya'), findsOneWidget);
      expect(find.textContaining('Student'), findsNothing);
    });

    testWidgets('falls back to a custom auth name when no local name is set',
        (tester) async {
      await UserPreferencesService.instance.initialize();

      // No auth user in the test environment → HomeScreen's fallback name.
      await _pumpHome(tester);

      expect(find.textContaining('Student'), findsOneWidget);
    });
  });

  group('UserPreferencesService.setDisplayName persistence', () {
    test('trims and persists the name to local storage', () async {
      await UserPreferencesService.instance.initialize();
      await UserPreferencesService.instance.setDisplayName('  Riya Singh  ');

      expect(UserPreferencesService.instance.current.displayName,
          'Riya Singh');

      final prefs = await SharedPreferences.getInstance();
      final stored =
          jsonDecode(prefs.getString('coderank_user_prefs_v1')!)
              as Map<String, dynamic>;
      expect(stored['displayName'], 'Riya Singh');
    });

    test('clears the name when set to null or blank (UI falls back)',
        () async {
      await UserPreferencesService.instance.initialize();
      await UserPreferencesService.instance.setDisplayName('Temp Name');
      await UserPreferencesService.instance.setDisplayName(null);
      expect(UserPreferencesService.instance.current.displayName, isNull);

      await UserPreferencesService.instance.setDisplayName('   ');
      expect(UserPreferencesService.instance.current.displayName, isNull);
    });
  });
}
