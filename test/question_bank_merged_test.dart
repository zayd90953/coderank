import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:coderank/features/practice/models/question_model.dart';

/// Post-merge bank-integrity gate (demo bank merged into the shipped bank).
///
/// Exercises the REAL bundled asset through rootBundle: the full bank must
/// parse with zero throws, every diagram reference must exist as a bundled
/// file (SVG or PNG — the shared QuestionDiagram tries both), and the demo
/// bank must actually be present (guards against an accidental revert).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('merged question bank (main + demo bank)', () {
    late List<dynamic> rawBank;

    setUpAll(() async {
      final jsonString = await rootBundle
          .loadString('lib/features/practice/data/questions.json');
      rawBank = jsonDecode(jsonString) as List<dynamic>;
    });

    QuestionModel parseAt(int i) =>
        QuestionModel.fromJson(rawBank[i] as Map<String, dynamic>);

    test('parses the entire merged bank without throwing', () {
      expect(rawBank.length, greaterThan(10000),
          reason: 'main bank (~4,982) + demo bank (5,891) merged');
      for (var i = 0; i < rawBank.length; i++) {
        // Throws on any malformed question — the reason field pinpoints it.
        parseAt(i);
        final q = parseAt(i);
        expect(q.options.length, 4, reason: '${q.id}: 4 options');
        expect(q.correctAnswer, inInclusiveRange(0, 3),
            reason: '${q.id}: correctAnswer range');
        expect(q.id, isNotEmpty, reason: 'index $i');
      }
    });

    test('every diagram reference resolves to a bundled SVG or PNG asset', () {
      final seen = <String>{};
      for (var i = 0; i < rawBank.length; i++) {
        final q = parseAt(i);
        if (q.diagramId == null) continue;
        expect(seen.contains(q.diagramId), isFalse,
            reason: '${q.id}: diagram id ${q.diagramId} reused (ambiguity)');
        seen.add(q.diagramId!);

        final svg = File('assets/practice/diagrams/${q.diagramId}.svg');
        final png = File('assets/practice/diagrams/${q.diagramId}.png');
        expect(svg.existsSync() || png.existsSync(), isTrue,
            reason:
                '${q.id}: diagram ${q.diagramId} missing from assets/practice/diagrams/');
      }
      expect(seen.length, greaterThanOrEqualTo(220),
          reason: 'the merged demo bank contributes 220 SVG figures');
    });

    test('demo bank is actually merged in (spot IDs from each source batch)', () {
      final ids = {
        for (var i = 0; i < rawBank.length; i++) (rawBank[i] as Map)['id'],
      };
      // Batch 1 (hand-authored), batch 2 (PYQ transcriptions), generated.
      expect(ids.contains('NEET-9001'), isTrue, reason: 'batch 1');
      expect(ids.any((id) => (id as String).startsWith('NEET-90')),
          isTrue, reason: 'batch 2');
      expect(ids.contains('NEET-15000'), isTrue, reason: 'generated bank');
    });

    test('no duplicate IDs across the whole merged bank', () {
      final ids = <String>[];
      for (final raw in rawBank) {
        ids.add((raw as Map<String, dynamic>)['id'] as String);
      }
      expect(ids.length, ids.toSet().length, reason: 'duplicate question IDs');
    });
  });
}
