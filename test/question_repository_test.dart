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
      // 750 Physics / 750 Chem / 1000 Bio exist = 2500 total.
      // Requesting beyond the pool simply takes what is available.
      final questions = await repo.getMockTestQuestions(
        physicsCount: 800,
        chemCount: 800,
        bioCount: 1200,
      );
      expect(questions.length, 2500,
          reason: 'Should return all available questions when requesting beyond pool.');
      expect(questions.where((q) => q.subject == 'Physics').length, 750);
      expect(questions.where((q) => q.subject == 'Chemistry').length, 750);
      expect(questions.where((q) => q.subject == 'Biology').length, 1000);
    });

    test('subject counts advertised by the app match the actual question bank',
        () async {
      final all = await repo.getAllQuestions();
      expect(all.length, 2500);
      expect(all.where((q) => q.subject == 'Physics').length, 750);
      expect(all.where((q) => q.subject == 'Chemistry').length, 750);
      expect(all.where((q) => q.subject == 'Biology').length, 1000);
    });
  });
}