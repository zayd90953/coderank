// R-7 regression tests: the shared ExplanationCard.
//
//   * Verdict header (Correct / Not quite / Time's up) with the raw
//     explanation body.
//   * Misconception callout appears only for a wrong, lettered pick with
//     a schema entry for THAT letter.
//   * App-format questions (no commonWrongReasoning) never show it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coderank/shared/widgets/explanation_card.dart';

Widget _host(Widget card) => MaterialApp(home: Scaffold(body: card));

void main() {
  testWidgets('correct answer shows verdict + explanation, no callout',
      (tester) async {
    await tester.pumpWidget(_host(ExplanationCard(
      selectedOptionIndex: 0,
      correctOptionIndex: 0,
      explanation: 'F = ma.',
      commonWrongReasoning: const {
        'B': 'confuses mass with weight',
      },
    )));

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('F = ma.'), findsOneWidget);
    expect(find.textContaining('TEMPTS YOU'), findsNothing);
  });

  testWidgets('wrong pick with a schema entry shows the misconception',
      (tester) async {
    await tester.pumpWidget(_host(ExplanationCard(
      selectedOptionIndex: 1, // B
      correctOptionIndex: 0,
      explanation: 'Meiosis I is reductional.',
      commonWrongReasoning: const {
        'B': 'skips a step — assumes meiosis I directly produces spermatids',
        'C': 'confuses spermatogenesis with oogenesis',
      },
    )));

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.text('WHY B TEMPTS YOU'), findsOneWidget);
    expect(
      find.text('skips a step — assumes meiosis I directly produces spermatids'),
      findsOneWidget,
    );
    // The entry for the UNCHOSEN wrong letter must NOT appear.
    expect(find.textContaining('oogenesis'), findsNothing);
  });

  testWidgets('wrong pick with no entry for that letter skips the callout',
      (tester) async {
    await tester.pumpWidget(_host(ExplanationCard(
      selectedOptionIndex: 3, // D — no entry in the map
      correctOptionIndex: 0,
      explanation: 'Meiosis I is reductional.',
      commonWrongReasoning: const {
        'B': 'skips a step',
      },
    )));

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.textContaining('TEMPTS YOU'), findsNothing);
  });

  testWidgets('timeout shows the timer verdict, never a callout',
      (tester) async {
    await tester.pumpWidget(_host(ExplanationCard(
      selectedOptionIndex: null,
      correctOptionIndex: 0,
      explanation: 'Meiosis I is reductional.',
      commonWrongReasoning: const {
        'B': 'skips a step',
      },
    )));

    expect(find.text("Time's up"), findsOneWidget);
    expect(find.textContaining('TEMPTS YOU'), findsNothing);
  });

  testWidgets('app-format question (no tagging) renders the classic card',
      (tester) async {
    await tester.pumpWidget(_host(ExplanationCard(
      selectedOptionIndex: 1,
      correctOptionIndex: 0,
      explanation: 'F = ma.',
    )));

    expect(find.text('Not quite'), findsOneWidget);
    expect(find.text('F = ma.'), findsOneWidget);
    expect(find.textContaining('TEMPTS YOU'), findsNothing);
  });
}
