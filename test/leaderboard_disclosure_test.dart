// T-2 regression tests: the leaderboard must be honest about its demo
// cohort — a clear disclosure near the title, a visible "Your progress" tag
// on the current user's row, and a "Demo cohort" label on every sample-peer
// row, so mock peers can never be mistaken for real CodeRank users.
// No backend behavior is added or asserted.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coderank/features/practice/models/practice_session.dart';
import 'package:coderank/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:coderank/shared/services/user_progress_service.dart';

void main() {
  setUp(() {
    // UserProgressService persists via SharedPreferences; keep it hermetic.
    SharedPreferences.setMockInitialValues({});
    UserProgressService.instance.progressNotifier.value =
        const UserProgressData();
  });

  /// Seeds one completed 100-question session (60 correct, 40 timeouts) so
  /// the B-5 ranking gate (100 questions) is met and the user's row is
  /// rendered among the cohort. Awarded XP: 60×15 + 100×5 = 1400.
  Future<void> seedPastRankingGate() async {
    final s = PracticeSession(subject: 'Physics', totalQuestions: 100);
    for (var i = 0; i < 60; i++) {
      s.recordAnswer(questionIndex: i, selectedAnswer: 0, correctAnswer: 0);
    }
    for (var i = 60; i < 100; i++) {
      s.recordTimeout(questionIndex: i);
    }
    await UserProgressService.instance.recordSession(s);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LeaderboardScreen()),
    );
    await tester.pumpAndSettle();
  }

  group('T-2 leaderboard honesty', () {
    testWidgets('shows the demo-cohort disclosure near the title',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.text(
          'Demo leaderboard — rankings are not live and do not represent '
          'actual CodeRank users.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tags the current user row as their real progress',
        (tester) async {
      await seedPastRankingGate();
      await pumpScreen(tester);
      expect(find.text('Your progress'), findsOneWidget);
    });

    testWidgets('labels every visible sample peer row as demo cohort',
        (tester) async {
      await seedPastRankingGate();
      await pumpScreen(tester);
      // Cohort sort with the seeded user at 1400 XP: the podium (top 3)
      // renders via the podium path, and ranks 4–11 (7 demo peers + the
      // user row) render via _buildRankingRow. Exactly 7 peer rows
      // therefore carry the label — the user's row must not.
      expect(
        find.textContaining('Demo cohort'),
        findsNWidgets(7),
        reason: 'Every mock peer row must be labelled; the user row must not',
      );
    });

    testWidgets('user row is not labelled as demo cohort',
        (tester) async {
      await seedPastRankingGate();
      await pumpScreen(tester);
      expect(
        find.text('Target AIIMS Delhi • 60% acc'),
        findsOneWidget,
        reason:
            'The real user row shows plain stats without the Demo cohort tag',
      );
    });
  });
}
