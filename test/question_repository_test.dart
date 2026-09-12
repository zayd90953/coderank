import 'package:flutter_test/flutter_test.dart';
import 'package:coderank/features/practice/data/question_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      // Post-AUD-1 pool: 643 Physics / 588 Chem / 998 Bio = 2229 total.
      // Requesting beyond the pool simply takes what is available.
      final questions = await repo.getMockTestQuestions(
        physicsCount: 800,
        chemCount: 800,
        bioCount: 1200,
      );
      expect(questions.length, 2229,
          reason: 'Should return all available questions when requesting beyond pool.');
      expect(questions.where((q) => q.subject == 'Physics').length, 643);
      expect(questions.where((q) => q.subject == 'Chemistry').length, 588);
      expect(questions.where((q) => q.subject == 'Biology').length, 998);
    });

    test('subject counts advertised by the app match the actual question bank',
        () async {
      final all = await repo.getAllQuestions();
      expect(all.length, 2229);
      expect(all.where((q) => q.subject == 'Physics').length, 643);
      expect(all.where((q) => q.subject == 'Chemistry').length, 588);
      expect(all.where((q) => q.subject == 'Biology').length, 998);
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