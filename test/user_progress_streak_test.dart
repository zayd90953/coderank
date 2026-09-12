// AUD-2 regression tests: the streak counts consecutive days with a
// COMPLETED session — not app opens.
//
//   * App open after a break  → streak expires to 0 (no XP awarded).
//   * App open within grace   → streak unchanged.
//   * Completing a session    → extends (yesterday) or starts (fresh).
//   * Second session same day → streak unchanged.
//
// Persistence is stubbed by pumping a SharedPreferences mock.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coderank/features/practice/models/practice_session.dart';
import 'package:coderank/shared/services/user_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Seeds the service's persisted JSON so `initialize()` loads the
  /// intended state instead of the brand-new-user default.
  Future<void> seedProgress(UserProgressData data) async {
    SharedPreferences.setMockInitialValues({
      'coderank_user_progress_v1': jsonEncode(data.toJson()),
    });
    UserProgressService.instance.progressNotifier.value = data;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Fresh in-memory state per test.
    UserProgressService.instance.progressNotifier.value =
        const UserProgressData();
  });

  PracticeSession session({int correct = 5, int total = 10}) {
    final s = PracticeSession(subject: 'Physics', totalQuestions: total);
    for (var i = 0; i < correct; i++) {
      s.recordAnswer(questionIndex: i, selectedAnswer: 0, correctAnswer: 0);
    }
    for (var i = correct; i < total; i++) {
      s.recordTimeout(questionIndex: i);
    }
    return s;
  }

  String dateStr(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  test('brand-new user has streak 0 and no lastActiveDate', () async {
    final svc = UserProgressService.instance;
    await svc.initialize();
    expect(svc.current.streakDays, 0);
    expect(svc.current.lastActiveDate, '');
  });

  test('completing a session starts the streak at 1', () async {
    final svc = UserProgressService.instance;
    await svc.recordSession(session());
    expect(svc.current.streakDays, 1);
    expect(svc.current.lastActiveDate, isNotEmpty);
  });

  test('second session the same day does not extend the streak', () async {
    final svc = UserProgressService.instance;
    await svc.recordSession(session());
    await svc.recordSession(session());
    expect(svc.current.streakDays, 1);
  });

  test('app open with no practice does not create a streak', () async {
    final svc = UserProgressService.instance;
    await svc.initialize();
    // Re-initialize (simulates another app open).
    await svc.initialize();
    expect(svc.current.streakDays, 0);
  });

  test('streak expires to 0 when last practice is older than yesterday',
      () async {
    final svc = UserProgressService.instance;
    final now = DateTime.now();
    final stale =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));

    await seedProgress(UserProgressData(
      streakDays: 7,
      lastActiveDate: dateStr(stale),
    ));

    await svc.initialize();
    expect(svc.current.streakDays, 0,
        reason: 'A 3-day-old streak is dead and must expire on app open');
  });

  test('streak survives app open within the grace window', () async {
    final svc = UserProgressService.instance;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    await seedProgress(UserProgressData(
      streakDays: 5,
      lastActiveDate: dateStr(yesterday),
    ));

    await svc.initialize();
    expect(svc.current.streakDays, 5,
        reason: 'Practiced yesterday: streak still alive on app open');
  });

  test('app open after a break never awards XP', () async {
    final svc = UserProgressService.instance;
    final now = DateTime.now();
    final stale =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));

    await seedProgress(UserProgressData(
      xpPoints: 500,
      streakDays: 7,
      lastActiveDate: dateStr(stale),
    ));

    await svc.initialize();
    expect(svc.current.xpPoints, 500);
  });
}
