// Group C regression tests: the target-picker sheet must (1) keep a
// selection after its own rebuild (the "cannot select any option" bug —
// state used to be re-initialized inside the StatefulBuilder builder), and
// (2) persist a cleared field as null (copyWith's `??` fallback used to
// make clearing impossible). Uses the real showTargetPickerSheet entry
// point end-to-end.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coderank/features/profile/presentation/sheets/target_picker_sheet.dart';
import 'package:coderank/shared/services/user_preferences_service.dart';

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showTargetPickerSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('target picker — selection sticks (Bug 2)', () {
    testWidgets('tapping an option updates the selection and Save persists it',
        (tester) async {
      await UserPreferencesService.instance.initialize();
      await _openSheet(tester);

      // Two "Not set" buttons exist (State + College); .first is State.
      await tester.tap(find.text('Not set').first);
      await tester.pumpAndSettle();

      // Pick Karnataka from the open menu (.last: menu item, not button).
      await tester.tap(find.text('Karnataka').last);
      await tester.pumpAndSettle();

      // Under the old bug the sheet rebuilt and snapped back to 'Not set'.
      expect(find.text('Karnataka'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget, reason: 'only College remains unset');

      // Save → the sheet pops and the choice lands in storage.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(UserPreferencesService.instance.current.targetState, 'Karnataka');
    });

    testWidgets('year selection sticks too', (tester) async {
      await UserPreferencesService.instance.initialize();
      await _openSheet(tester);

      await tester.tap(find.text('NEET 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NEET 2027').last);
      await tester.pumpAndSettle();

      expect(find.text('NEET 2027'), findsOneWidget);
    });
  });

  group('target persistence (setTarget)', () {
    test('saves a selection and reads it back', () async {
      await UserPreferencesService.instance.initialize();

      await UserPreferencesService.instance.setTarget(
        year: 2027,
        state: 'Delhi',
        college: 'AIIMS Delhi',
      );

      final prefs = UserPreferencesService.instance.current;
      expect(prefs.targetYear, 2027);
      expect(prefs.targetState, 'Delhi');
      expect(prefs.targetCollege, 'AIIMS Delhi');
    });

    test('setTarget(null) actually CLEARS a field (copyWith regression)',
        () async {
      await UserPreferencesService.instance.initialize();

      await UserPreferencesService.instance.setTarget(
        year: 2027,
        state: 'Delhi',
        college: 'AIIMS Delhi',
      );
      await UserPreferencesService.instance.setTarget(
        year: 2028,
        state: null, // clear
        college: null, // clear
      );

      final prefs = UserPreferencesService.instance.current;
      expect(prefs.targetYear, 2028);
      expect(prefs.targetState, isNull,
          reason: 'null must clear the stored state');
      expect(prefs.targetCollege, isNull,
          reason: 'null must clear the stored college');
    });

    test('setTarget preserves unrelated preferences', () async {
      await UserPreferencesService.instance.initialize();
      await UserPreferencesService.instance.setDisplayName('Aarav');

      await UserPreferencesService.instance.setTarget(
        year: 2027,
        state: 'Delhi',
        college: null,
      );

      final prefs = UserPreferencesService.instance.current;
      expect(prefs.displayName, 'Aarav');
      expect(prefs.targetState, 'Delhi');
    });
  });
}
