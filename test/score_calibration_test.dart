// R-9 regression tests: mock test scoring calibration.
//
//   * Projection holds pace across unanswered questions.
//   * Percentile curve is monotone and bounded.
//   * Uncertainty band widens as attempts shrink.
//   * AIR mapping only past the threshold, lower rank = better score.
//   * Results screen renders the prediction card.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coderank/features/mock_test/data/score_calibration.dart';
import 'package:coderank/features/mock_test/presentation/mock_test_results_screen.dart';
import 'package:coderank/features/practice/models/question_model.dart';

QuestionModel _q(String id) => QuestionModel(
      id: id,
      subject: 'Physics',
      branch: 'Class 12',
      chapter: 'Optics',
      coreConcept: 'c',
      questionType: 'Recall',
      difficulty: 'Medium',
      question: 'q?',
      options: const ['A', 'B', 'C', 'D'],
      correctAnswer: 0,
      explanation: 'e',
      sourcePattern: 'Standard',
    );

void main() {
  group('ScoreCalibration.from — projection', () {
    test('perfect full paper projects to the max score', () {
      final c = ScoreCalibration.from(
        correct: 180,
        wrong: 0,
        totalQuestions: 180,
      )!;
      expect(c.projectedScore, 720);
      expect(c.percentileMid, greaterThan(99));
    });

    test('holds per-attempt pace across the unattempted remainder', () {
      // 90 attempted: 60 correct (240), 30 wrong (−30) → 210/90 = 2.333/attempt.
      // 90 unattempted → 210 + 210 = 420 projected.
      final c = ScoreCalibration.from(
        correct: 60,
        wrong: 30,
        totalQuestions: 180,
      )!;
      expect(c.projectedScore, 420);
      expect(c.perAttemptMark, closeTo(2.333, 0.001));
    });

    test('returns null when nothing was attempted', () {
      expect(
        ScoreCalibration.from(correct: 0, wrong: 0, totalQuestions: 180),
        isNull,
      );
    });
  });

  group('ScoreCalibration.from — percentile band', () {
    test('is monotone: a better score never predicts a lower percentile',
        () {
      double? prevMid;
      for (final correct in [30, 60, 90, 120, 150, 180]) {
        final c = ScoreCalibration.from(
          correct: correct,
          wrong: 0,
          totalQuestions: 180,
        )!;
        if (prevMid != null) {
          expect(c.percentileMid, greaterThanOrEqualTo(prevMid));
        }
        prevMid = c.percentileMid;
      }
    });

    test('band widens with thinner data', () {
      final thin = ScoreCalibration.from(
        correct: 10,
        wrong: 2,
        totalQuestions: 180,
      )!; // 12/180 attempted
      final full = ScoreCalibration.from(
        correct: 150,
        wrong: 30,
        totalQuestions: 180,
      )!; // full paper
      final thinWidth = thin.percentileHigh - thin.percentileLow;
      final fullWidth = full.percentileHigh - full.percentileLow;
      expect(thinWidth, greaterThan(fullWidth));
    });

    test('stays within [0, 100]', () {
      final c = ScoreCalibration.from(
        correct: 5,
        wrong: 40,
        totalQuestions: 180,
      )!;
      expect(c.percentileLow, greaterThanOrEqualTo(0));
      expect(c.percentileHigh, lessThanOrEqualTo(100));
    });
  });

  group('ScoreCalibration.from — AIR', () {
    test('suppressed below the attempt threshold', () {
      final c = ScoreCalibration.from(
        correct: 10,
        wrong: 5,
        totalQuestions: 180,
      )!; // 15 attempted < 45
      expect(c.predictedAir, isNull);
    });

    test('shown past the threshold, band brackets the midpoint', () {
      final c = ScoreCalibration.from(
        correct: 100,
        wrong: 20,
        totalQuestions: 180,
      )!; // 120 attempted
      expect(c.predictedAir, isNotNull);
      expect(c.predictedAirLow!, lessThanOrEqualTo(c.predictedAir!));
      expect(c.predictedAir!, lessThanOrEqualTo(c.predictedAirHigh!));
    });

    test('a better score predicts a better (lower) AIR', () {
      final weak = ScoreCalibration.from(
        correct: 50,
        wrong: 40,
        totalQuestions: 180,
      )!;
      final strong = ScoreCalibration.from(
        correct: 140,
        wrong: 20,
        totalQuestions: 180,
      )!;
      expect(strong.predictedAir!, lessThan(weak.predictedAir!));
    });
  });

  group('Mock results — prediction card', () {
    testWidgets('renders projection, percentile band and the disclaimer',
        (tester) async {
      final questions = List.generate(60, (i) => _q('M$i'));
      final answers = List<int?>.filled(60, 0); // all correct
      answers[59] = null; // one skipped → projection is visible

      await tester.pumpWidget(MaterialApp(
        home: MockTestResultsScreen(
          questions: questions,
          selectedAnswers: answers,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('NEET PREDICTION'), findsOneWidget);
      expect(find.textContaining('Projected score:'), findsOneWidget);
      expect(find.textContaining('Percentile ~'), findsOneWidget);
      expect(
        find.textContaining('Historical trend estimate — not a guarantee.'),
        findsOneWidget,
      );
    });
  });
}
