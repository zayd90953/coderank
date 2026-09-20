import 'package:flutter_test/flutter_test.dart';
import 'package:coderank/features/practice/data/question_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuestionRepository — chapter/topic/bloom queries (R-2)', () {
    final repo = QuestionRepository();

    test('getChapterCoverage returns sorted, positive counts', () async {
      final coverage = await repo.getChapterCoverage('Biology');
      expect(coverage, isNotEmpty);
      final keys = coverage.keys.toList();
      expect(keys, equals(List<String>.from(keys)..sort()));
      for (final count in coverage.values) {
        expect(count, greaterThan(0));
      }
    });

    test('getQuestionsByChapter returns only that chapter', () async {
      final coverage = await repo.getChapterCoverage('Physics');
      final chapter = coverage.keys.first;
      final questions = await repo.getQuestionsByChapter('Physics', chapter);
      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(q.subject, 'Physics');
        expect(q.chapter, chapter);
      }
      expect(questions.length, coverage[chapter]);
    });

    test('topic and bloom queries stay null-safe', () async {
      // App-format questions carry no topic/bloom tags; schema-format
      // questions do. Either way the queries must not throw — an empty
      // result is only guaranteed while the bank stays app-format-only.
      final topics = await repo.getTopicsForChapter('Biology', 'No such chapter');
      expect(topics, isEmpty);
      expect(
        await repo.getQuestionsByTopic('Biology', 'No such topic'),
        isEmpty,
      );
    });
  });

  group('QuestionRepository — mock test paper composition (P1-3)', () {
    final repo = QuestionRepository();

    test('getMockTestQuestions returns 180 questions: 45/45/90', () async {
      final questions = await repo.getMockTestQuestions(
        physicsCount: 45,
        chemCount: 45,
        bioCount: 90,
      );

      expect(questions.length, 180,
          reason: 'Full NEET paper must be exactly 180 questions');

      final physics = questions.where((q) => q.subject == 'Physics').length;
      final chem = questions.where((q) => q.subject == 'Chemistry').length;
      final bio = questions.where((q) => q.subject == 'Biology').length;

      expect(physics, 45);
      expect(chem, 45);
      expect(bio, 90);
    });

    test('questions are grouped Physics -> Chemistry -> Biology (NEET order)',
        () async {
      final questions = await repo.getMockTestQuestions(
        physicsCount: 45,
        chemCount: 45,
        bioCount: 90,
      );

      final subjects = questions.map((q) => q.subject).toList();
      final firstChem = subjects.indexOf('Chemistry');
      final firstBio = subjects.indexOf('Biology');
      final lastPhysics = subjects.lastIndexOf('Physics');
      final lastChem = subjects.lastIndexOf('Chemistry');
      final lastBio = subjects.lastIndexOf('Biology');

      // All Physics questions come before the first Chemistry question…
      expect(lastPhysics, lessThan(firstChem),
          reason: 'All Physics questions must precede Chemistry');
      // …and all Chemistry before the first Biology question.
      expect(lastChem, lessThan(firstBio),
          reason: 'All Chemistry questions must precede Biology');
      // The full blocks fill the paper without interleaving.
      expect(lastBio, 179);
    });

    test('requesting more than the pool size returns available questions',
        () async {
      // Each section is capped at min(requested, subject pool size), so
      // the total is the sum of per-section minimums — regardless of how
      // large the underlying bank is.
      final all = await repo.getAllQuestions();
      int pool(String subject) =>
          all.where((q) => q.subject == subject).length;
      const reqP = 800, reqC = 800, reqB = 1200;

      final questions = await repo.getMockTestQuestions(
        physicsCount: reqP,
        chemCount: reqC,
        bioCount: reqB,
      );

      final expP = pool('Physics') < reqP ? pool('Physics') : reqP;
      final expC = pool('Chemistry') < reqC ? pool('Chemistry') : reqC;
      final expB = pool('Biology') < reqB ? pool('Biology') : reqB;

      expect(questions.length, expP + expC + expB,
          reason: 'Each section is capped at its requested count or pool size.');
      expect(questions.where((q) => q.subject == 'Physics').length, expP);
      expect(questions.where((q) => q.subject == 'Chemistry').length, expC);
      expect(questions.where((q) => q.subject == 'Biology').length, expB);
    });

    test('every bank question is one of the three NEET subjects', () async {
      final all = await repo.getAllQuestions();
      expect(all, isNotEmpty);
      const subjects = {'Physics', 'Chemistry', 'Biology'};
      for (final q in all) {
        expect(subjects.contains(q.subject), isTrue,
            reason: 'Question ${q.id} has unexpected subject ${q.subject}');
      }
    });
  });

  group('QuestionRepository — bank integrity (AUD-1)', () {
    final repo = QuestionRepository();

    test('no question has duplicate option values', () async {
      final all = await repo.getAllQuestions();
      for (final q in all) {
        final normalized =
            q.options.map((o) => o.trim().toLowerCase()).toSet();
        expect(normalized.length, q.options.length,
            reason: 'Question ${q.id} has duplicate option values');
      }
    });

    test('every correctAnswer index is valid', () async {
      final all = await repo.getAllQuestions();
      for (final q in all) {
        expect(q.correctAnswer, inInclusiveRange(0, q.options.length - 1),
            reason: 'Question ${q.id} has an out-of-range correctAnswer');
      }
    });

    test('every question has at least 3 options', () async {
      final all = await repo.getAllQuestions();
      for (final q in all) {
        expect(q.options.length, greaterThanOrEqualTo(3),
            reason: 'Question ${q.id} has fewer than 3 options');
      }
    });

    test('no duplicate question texts in the bank', () async {
      final all = await repo.getAllQuestions();
      final texts = all.map((q) => q.question.trim().toLowerCase()).toSet();
      expect(texts.length, all.length,
          reason: 'The bank contains duplicate question texts');
    });
  });
}