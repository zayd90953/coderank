// Regression test: question palette with a 45-question list.
//
// _openPalette used to hardcode section boundaries 0/45/90/length. Quick Mock
// Test has 45 questions (15/15/15) so opening the palette threw a RangeError.
// This test builds MockTestQuestionScreen with a 45-question list and verifies
// the palette opens without throwing, and renders the three expected sections.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coderank/core/design/app_theme.dart';
import 'package:coderank/features/mock_test/presentation/mock_test_question_screen.dart';
import 'package:coderank/features/practice/models/question_model.dart';

QuestionModel _buildQuestion(String subject, int n) {
  return QuestionModel(
    id: '${subject.toLowerCase()}-$n',
    subject: subject,
    branch: 'Test',
    chapter: 'Test',
    coreConcept: 'Test',
    questionType: 'mcq',
    difficulty: 'Easy',
    question: '$subject Q$n',
    options: const ['A', 'B', 'C', 'D'],
    correctAnswer: 0,
    explanation: 'Test',
    sourcePattern: 'Test',
  );
}

List<QuestionModel> _quickQuestions() {
  return [
    for (var i = 0; i < 15; i++) _buildQuestion('Physics', i),
    for (var i = 0; i < 15; i++) _buildQuestion('Chemistry', i),
    for (var i = 0; i < 15; i++) _buildQuestion('Biology', i),
  ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('A-1 — Mock test palette opens on Quick mock (45 Qs)', () {
    testWidgets('palette opens without RangeError on 45-question list',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: MockTestQuestionScreen(questions: _quickQuestions()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the palette button (matched by its tooltip). Before A-1, this
      // crashed with RangeError because section boundaries were hardcoded.
      await tester.tap(find.byTooltip('Question Palette'));
      await tester.pumpAndSettle();

      // The palette header is the smoking gun — it only renders if
      // showModalBottomSheet completed without throwing.
      expect(find.text('Question Palette'), findsOneWidget);

      // All three section headers must be present in the widget tree
      // (they may not all be visible if the sheet is small, but they must
      // be built). Drag the sheet up to expand it, then verify.
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.text('PHYSICS'), findsOneWidget);
      expect(find.text('CHEMISTRY'), findsOneWidget);
      expect(find.text('BIOLOGY'), findsOneWidget);

      // The first section's question cells are visible. "1" must render.
      // (Other sections may be below the fold; the scroll above expanded
      // the sheet but the ListView still clips.)
      expect(find.text('1'), findsAtLeastNWidgets(1),
          reason: 'At least one "1" cell must render — proves the first '
              'section is iterating over 15 cells without crashing');
    });
  });
}
