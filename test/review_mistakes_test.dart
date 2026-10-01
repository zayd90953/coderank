// M-7 regression tests: mistake review.
//
//   * resolveQuestions returns null with no unresolved mistakes and
//     resolves seeded mistake IDs against the real bank.
//   * buildScreen labels the session by its majority subject.
//   * QuestionScreen(questionsOverride) runs the exact list, untimed, and
//     a later correct answer resolves the mistake in the R-3 memory while
//     a wrong answer stays unresolved.
//   * Practice Hub shows the Review Mistakes card only with mistakes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coderank/features/practice/data/question_repository.dart';
import 'package:coderank/features/practice/models/question_model.dart';
import 'package:coderank/features/practice/presentation/practice_screen.dart';
import 'package:coderank/features/practice/presentation/question/question_screen.dart';
import 'package:coderank/features/practice/presentation/question/review_mistakes.dart';
import 'package:coderank/features/practice/presentation/results/results_screen.dart';
import 'package:coderank/shared/services/user_progress_service.dart';
import 'package:coderank/shared/services/weak_area_tracking_service.dart';

QuestionModel _q(String id, String subject, String chapter) => QuestionModel(
      id: id,
      subject: subject,
      branch: 'Class 12',
      chapter: chapter,
      coreConcept: 'concept',
      questionType: 'Recall',
      difficulty: 'Medium',
      question: 'q?',
      options: const ['opt one', 'opt two', 'opt three', 'opt four'],
      correctAnswer: 0,
      explanation: 'e',
      sourcePattern: 'Standard',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Fresh in-memory state per test.
    UserProgressService.instance.progressNotifier.value =
        const UserProgressData();
    WeakAreaTrackingService.instance.weakAreasNotifier.value =
        const WeakAreaData();
  });

  group('ReviewMistakes.resolveQuestions', () {
    test('returns null with no unresolved mistakes', () async {
      expect(await ReviewMistakes.resolveQuestions(), isNull);
    });

    test('resolves seeded mistakes against the real bank', () async {
      final repo = QuestionRepository();
      final physics = await repo.getQuestionsBySubject('Physics');
      expect(physics, isNotEmpty);
      final a = physics.first;
      final b = physics[physics.length ~/ 2];

      await WeakAreaTrackingService.instance.recordQuestionOutcomes([
        (question: a, isCorrect: false),
        (question: b, isCorrect: false),
      ]);

      final resolved = await ReviewMistakes.resolveQuestions();
      expect(resolved, isNotNull);
      expect(resolved!.map((q) => q.id), containsAll([a.id, b.id]));
    });

    test('stale IDs (no longer in the bank) yield nothing reviewable', () async {
      // Seed a mistake whose ID the bank doesn't contain by recording a
      // fake question and then emptying the bank lookup via a bogus ID —
      // resolveQuestions must return null rather than an empty session.
      await WeakAreaTrackingService.instance.recordQuestionOutcomes([
        (question: _q('DOES-NOT-EXIST', 'Physics', 'Optics'), isCorrect: false),
      ]);
      expect(await ReviewMistakes.resolveQuestions(), isNull);
    });
  });

  group('ReviewMistakes.buildScreen', () {
    test('labels the session by its majority subject', () async {
      // Real bank questions — buildScreen resolves IDs against the bank,
      // so fake IDs would come back stale and yield null.
      final repo = QuestionRepository();
      final physics = await repo.getQuestionsBySubject('Physics');
      final biology = await repo.getQuestionsBySubject('Biology');
      final questions = [physics.first, physics[1], biology.first];
      await WeakAreaTrackingService.instance
          .recordQuestionOutcomes([for (final q in questions) (question: q, isCorrect: false)]);

      final screen = await ReviewMistakes.buildScreen();
      expect(screen, isNotNull);
      expect(screen!.subject, 'Physics', reason: '2 of 3 mistakes are Physics');
      expect(screen.timeLimit, isNull, reason: 'review sessions are untimed');
    });
  });

  group('review session runner (questionsOverride)', () {
    testWidgets(
        'runs the exact override list and resolves the mistake on correct',
        (tester) async {
      final questions = [
        _q('R1', 'Physics', 'Optics'),
        _q('R2', 'Physics', 'Optics'),
      ];
      await WeakAreaTrackingService.instance.recordQuestionOutcomes([
        (question: questions[0], isCorrect: false),
        (question: questions[1], isCorrect: false),
      ]);

      await tester.pumpWidget(MaterialApp(
        home: QuestionScreen(
          subject: 'Physics',
          questionsOverride: questions,
        ),
      ));
      await tester.pumpAndSettle();

      // Q1 answered correctly (option index 0 is correctAnswer).
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Next Question'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      // Q2 answered wrong (index 2 != 0).
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Check Answer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();
      // Last question's Next pushes the results screen.
      await tester.ensureVisible(find.text('Next Question'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next Question'));
      await tester.pumpAndSettle();

      final svc = WeakAreaTrackingService.instance;
      // The runner shuffles the override list, so which question lands
      // first is random — assert order-agnostically: the correct answer
      // must resolve its mistake, the wrong one must stay unresolved.
      final resolvedCount =
          [svc.isRecentMistake('R1'), svc.isRecentMistake('R2')]
              .where((unresolved) => !unresolved)
              .length;
      expect(resolvedCount, 1,
          reason: 'exactly the correctly-answered mistake got resolved');
      expect(
        svc.isRecentMistake('R1') != svc.isRecentMistake('R2'),
        isTrue,
        reason: 'one resolved, one still unresolved',
      );

      // Both questions completed and recorded; results screen pushed.
      expect(find.byType(ResultsScreen), findsOneWidget);
    });
  });

  group('Practice Hub — Review Mistakes card', () {
    testWidgets('hidden without mistakes, shown with them', (tester) async {
      await tester.pumpWidget(MaterialApp(home: const PracticeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Review Mistakes'), findsNothing);

      await WeakAreaTrackingService.instance.recordQuestionOutcome(
        _q('R1', 'Physics', 'Optics'),
        isCorrect: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Mistakes'), findsOneWidget);
      expect(find.text('Revisit the 1 question you missed'), findsOneWidget);
    });
  });
}
