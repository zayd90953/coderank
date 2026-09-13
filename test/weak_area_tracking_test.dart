// R-3 regression tests: weak-area tracking service.
//
//   * Per-chapter attempt/correct accumulation and accuracy.
//   * Recent-mistakes memory: newest-first, cleared on later correct,
//     capped at 60 entries.
//   * weakestChapters ordering (accuracy, then attempts, then name).
//   * unattemptedChapters.
//   * Persistence round-trip through SharedPreferences.
//   * reset() clears everything.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coderank/features/practice/models/question_model.dart';
import 'package:coderank/shared/services/weak_area_tracking_service.dart';

QuestionModel q(String id, String subject, String chapter) =>
    QuestionModel(
      id: id,
      subject: subject,
      branch: 'Class 12',
      chapter: chapter,
      coreConcept: 'concept',
      questionType: 'Recall',
      difficulty: 'Medium',
      question: 'q?',
      options: const ['A', 'B', 'C', 'D'],
      correctAnswer: 0,
      explanation: 'e',
      sourcePattern: 'Standard',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WeakAreaTrackingService.instance.weakAreasNotifier.value =
        const WeakAreaData();
  });

  group('chapter stats', () {
    test('accumulates attempts and computes accuracy', () async {
      final svc = WeakAreaTrackingService.instance;
      final question = q('PHY-1', 'Physics', 'Laws of Motion');

      await svc.recordQuestionOutcome(question, isCorrect: true);
      await svc.recordQuestionOutcome(question, isCorrect: false);
      await svc.recordQuestionOutcome(question, isCorrect: false);

      final stats = svc.weakestChapters('Physics');
      expect(stats.length, 1);
      expect(stats.single.attempts, 3);
      expect(stats.single.correct, 1);
      expect(stats.single.accuracy, closeTo(33.33, 0.01));
    });

    test('separates subjects and chapters by key', () async {
      final svc = WeakAreaTrackingService.instance;
      await svc.recordQuestionOutcome(
          q('P1', 'Physics', 'Optics'), isCorrect: true);
      await svc.recordQuestionOutcome(
          q('P2', 'Physics', 'Laws of Motion'), isCorrect: false);
      await svc.recordQuestionOutcome(
          q('B1', 'Biology', 'Optics'), isCorrect: false);

      expect(svc.weakestChapters('Physics').length, 2);
      expect(svc.weakestChapters('Biology').length, 1);
      expect(svc.weakestChapters('Chemistry'), isEmpty);
    });
  });

  group('recent mistakes', () {
    test('wrong answers recorded newest-first, later correct clears',
        () async {
      final svc = WeakAreaTrackingService.instance;
      await svc.recordQuestionOutcome(
          q('Q1', 'Physics', 'Optics'), isCorrect: false);
      await svc.recordQuestionOutcome(
          q('Q2', 'Physics', 'Optics'), isCorrect: false);
      expect(svc.recentMistakeIds(), ['Q2', 'Q1']);
      expect(svc.isRecentMistake('Q1'), isTrue);

      // A later correct answer resolves the mistake.
      await svc.recordQuestionOutcome(
          q('Q1', 'Physics', 'Optics'), isCorrect: true);
      expect(svc.recentMistakeIds(), ['Q2']);
      expect(svc.isRecentMistake('Q1'), isFalse);
    });

    test('is capped at 60 entries', () async {
      final svc = WeakAreaTrackingService.instance;
      for (var i = 0; i < 70; i++) {
        await svc.recordQuestionOutcome(
            q('Q$i', 'Physics', 'Optics'), isCorrect: false);
      }
      final ids = svc.recentMistakeIds();
      expect(ids.length, 60);
      // Newest first: the latest miss survives, the oldest fell off.
      expect(ids.first, 'Q69');
      expect(ids.contains('Q0'), isFalse);
    });

    test('limit parameter truncates the view, not the store', () async {
      final svc = WeakAreaTrackingService.instance;
      for (var i = 0; i < 5; i++) {
        await svc.recordQuestionOutcome(
            q('Q$i', 'Physics', 'Optics'), isCorrect: false);
      }
      expect(svc.recentMistakeIds(limit: 2), ['Q4', 'Q3']);
      expect(svc.recentMistakeIds().length, 5);
    });
  });

  group('weakestChapters ordering', () {
    test('lowest accuracy first; ties break by attempts then name',
        () async {
      final svc = WeakAreaTrackingService.instance;

      // Alpha: 0% (2 attempts). Beta: 0% (1 attempt). Gamma: 100%.
      await svc.recordQuestionOutcome(
          q('A1', 'Physics', 'Alpha'), isCorrect: false);
      await svc.recordQuestionOutcome(
          q('A2', 'Physics', 'Alpha'), isCorrect: false);
      await svc.recordQuestionOutcome(
          q('B1', 'Physics', 'Beta'), isCorrect: false);
      await svc.recordQuestionOutcome(
          q('G1', 'Physics', 'Gamma'), isCorrect: true);

      final order =
          svc.weakestChapters('Physics').map((s) => s.chapter).toList();
      expect(order, ['Alpha', 'Beta', 'Gamma']);
    });
  });

  group('unattemptedChapters', () {
    test('returns chapters with zero attempts', () async {
      final svc = WeakAreaTrackingService.instance;
      await svc.recordQuestionOutcome(
          q('P1', 'Physics', 'Optics'), isCorrect: true);

      final unattempted = await svc.unattemptedChapters('Physics', {
        'Optics',
        'Laws of Motion',
        'Thermodynamics',
      });
      expect(unattempted, {'Laws of Motion', 'Thermodynamics'});
    });
  });

  group('persistence', () {
    test('state survives a re-initialize (storage round-trip)', () async {
      final svc = WeakAreaTrackingService.instance;
      await svc.recordQuestionOutcome(
          q('Q1', 'Biology', 'Genetics'), isCorrect: false);
      await svc.recordQuestionOutcome(
          q('Q2', 'Biology', 'Genetics'), isCorrect: true);

      // Simulate an app restart: re-read from SharedPreferences.
      await svc.initialize();
      final stats = svc.weakestChapters('Biology');
      expect(stats.single.attempts, 2);
      expect(stats.single.correct, 1);
      expect(svc.recentMistakeIds(), ['Q1']);
    });
  });

  group('reset', () {
    test('clears chapters and mistakes, including persisted state',
        () async {
      final svc = WeakAreaTrackingService.instance;
      await svc.recordQuestionOutcome(
          q('Q1', 'Physics', 'Optics'), isCorrect: false);
      expect(svc.current.chapters, isNotEmpty);

      await svc.reset();
      expect(svc.current.chapters, isEmpty);
      expect(svc.current.recentMistakes, isEmpty);

      // Persisted state is gone too.
      await svc.initialize();
      expect(svc.current.chapters, isEmpty);
    });
  });
}
