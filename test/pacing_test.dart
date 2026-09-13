// R-8 regression tests: time-pacing features.
//
//   * PaceUtils: expected time by difficulty, slow-answer threshold
//     (> 1.5x expected), status classification boundaries.
//   * Practice results: the pacing nudge appears at 2+ slow answers and
//     stays hidden otherwise.
//   * Mock results: the average-time stat renders when timing data is
//     provided and stays hidden for legacy (null) callers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coderank/features/practice/models/practice_session.dart';
import 'package:coderank/features/practice/models/question_model.dart';
import 'package:coderank/features/mock_test/presentation/mock_test_results_screen.dart';
import 'package:coderank/features/practice/presentation/results/results_screen.dart';
import 'package:coderank/shared/utils/pacing_utils.dart';

QuestionModel _q(String difficulty) => QuestionModel(
      id: 'Q-$difficulty',
      subject: 'Physics',
      branch: 'Class 12',
      chapter: 'Optics',
      coreConcept: 'c',
      questionType: 'Recall',
      difficulty: difficulty,
      question: 'q?',
      options: const ['A', 'B', 'C', 'D'],
      correctAnswer: 0,
      explanation: 'e',
      sourcePattern: 'Standard',
    );

void main() {
  group('PaceUtils.expectedSeconds', () {
    test('follows the difficulty-aware defaults', () {
      expect(PaceUtils.expectedSeconds(_q('Easy')), 45);
      expect(PaceUtils.expectedSeconds(_q('Medium')), 75);
      expect(PaceUtils.expectedSeconds(_q('Hard')), 110);
    });
  });

  group('PaceUtils.isSlowAnswer', () {
    test('threshold is strictly above 1.5x expected', () {
      // Medium: expected 75 → 1.5x = 112.5s.
      expect(PaceUtils.isSlowAnswer(_q('Medium'), 112), isFalse);
      expect(PaceUtils.isSlowAnswer(_q('Medium'), 113), isTrue);
      // Easy: expected 45 → 67.5s.
      expect(PaceUtils.isSlowAnswer(_q('Easy'), 67), isFalse);
      expect(PaceUtils.isSlowAnswer(_q('Easy'), 68), isTrue);
    });
  });

  group('PaceUtils.paceStatus', () {
    test('classifies the four bands', () {
      // Medium: expected 75.
      expect(PaceUtils.paceStatus(_q('Medium'), 45), PaceStatus.fast);
      expect(PaceUtils.paceStatus(_q('Medium'), 75), PaceStatus.onPace);
      expect(PaceUtils.paceStatus(_q('Medium'), 100), PaceStatus.slow);
      expect(PaceUtils.paceStatus(_q('Medium'), 200), PaceStatus.verySlow);
    });
  });

  group('Practice results — pacing nudge', () {
    PracticeSession session({int correct = 3, int total = 5}) {
      final s = PracticeSession(subject: 'Physics', totalQuestions: total);
      for (var i = 0; i < correct; i++) {
        s.recordAnswer(questionIndex: i, selectedAnswer: 0, correctAnswer: 0);
      }
      for (var i = correct; i < total; i++) {
        s.recordAnswer(questionIndex: i, selectedAnswer: 1, correctAnswer: 0);
      }
      return s;
    }

    Widget host({int? slow}) => MaterialApp(
          home: ResultsScreen(
            session: session(),
            xpEarned: 20,
            questionCount: 5,
            difficulty: 'Mixed',
            slowAnswerCount: slow,
          ),
        );

    testWidgets('hidden below the 2-slow-answer pattern threshold',
        (tester) async {
      await tester.pumpWidget(host(slow: 1));
      await tester.pumpAndSettle(); // flush the entrance choreography
      expect(find.textContaining('pacing yourself'), findsNothing);
    });

    testWidgets('shown at 2+ with the count', (tester) async {
      await tester.pumpWidget(host(slow: 3));
      await tester.pumpAndSettle(); // flush the entrance choreography
      expect(
        find.text(
            '3 answers took longer than expected — try pacing yourself.'),
        findsOneWidget,
      );
    });
  });

  group('Mock results — average time stat', () {
    final questions = [_q('Medium'), _q('Medium'), _q('Medium')];

    Widget host({List<int>? seconds}) => MaterialApp(
          home: MockTestResultsScreen(
            questions: questions,
            selectedAnswers: const [0, null, 1],
            secondsSpent: seconds,
          ),
        );

    testWidgets('renders the average over attempted questions',
        (tester) async {
      // Attempted: q0 (60s) and q2 (90s) → avg 75. Skipped q1 excluded.
      await tester.pumpWidget(host(seconds: [60, 0, 90]));
      expect(find.textContaining('Avg 75'), findsOneWidget);
    });

    testWidgets('hidden when no timing data (legacy callers)',
        (tester) async {
      await tester.pumpWidget(host());
      expect(find.textContaining('Avg'), findsNothing);
    });
  });
}
