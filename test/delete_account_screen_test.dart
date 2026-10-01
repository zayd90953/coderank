import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coderank/features/profile/presentation/delete_account_screen.dart';
import 'package:coderank/features/welcome/presentation/welcome_screen.dart';
import 'package:coderank/shared/services/user_preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    Future<void> Function()? onDeleteRequested,
    VoidCallback? onWiped,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeleteAccountScreen(
          onDeleteRequested: onDeleteRequested,
          onWiped: onWiped,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> confirmAndTap(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Permanently Delete Everything'),
    );
    await tester.pump();
  }

  testWidgets('button stays disabled until DELETE is typed', (tester) async {
    await pumpScreen(tester, onWiped: () {});

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Permanently Delete Everything'),
    );
    expect(button.onPressed, isNull, reason: 'empty input must not enable');

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();

    final enabled = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Permanently Delete Everything'),
    );
    expect(enabled.onPressed, isNotNull,
        reason: 'case-insensitive DELETE enables the button');
  });

  testWidgets('failed server wipe keeps the user on screen with an error',
      (tester) async {
    var wipeRan = false;
    await pumpScreen(
      tester,
      onDeleteRequested: () async => throw Exception('firestore down'),
      onWiped: () => wipeRan = true,
    );
    await confirmAndTap(tester);

    expect(find.byType(DeleteAccountScreen), findsOneWidget,
        reason: 'failed wipe must NOT navigate away');
    expect(find.textContaining('Try again'), findsOneWidget);
    expect(wipeRan, isFalse,
        reason: 'local wipe must not run when the server step fails');
  });

  testWidgets('successful wipe exits to Welcome', (tester) async {
    var serverWiped = false;
    await pumpScreen(
      tester,
      onDeleteRequested: () async => serverWiped = true,
      // Mirrors the production branch's exit route (pushAndRemoveUntil →
      // WelcomeScreen) without routing the real navigator.
      onWiped: () => tester.pumpWidget(
        const MaterialApp(home: WelcomeScreen()),
      ),
    );
    await confirmAndTap(tester);
    await tester.pump();

    expect(serverWiped, isTrue, reason: 'server step runs before the wipe');
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('local wipe clears persisted prefs after success',
      (tester) async {
    // Seed a non-default preference, then run the success path.
    await UserPreferencesService.instance.initialize();
    await UserPreferencesService.instance.setDisplayName('Aarav');
    expect(UserPreferencesService.instance.current.displayName, 'Aarav');

    await pumpScreen(
      tester,
      onDeleteRequested: () async {},
      onWiped: () {},
    );
    await confirmAndTap(tester);

    expect(
      UserPreferencesService.instance.current.displayName,
      isNull,
      reason: 'clearAllLocalData must revert prefs to factory defaults',
    );
  });
}
