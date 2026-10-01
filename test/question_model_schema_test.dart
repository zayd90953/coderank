import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:coderank/features/practice/models/question_model.dart';

void main() {
  group('QuestionModel.fromJson — app format (original bank)', () {
    test('parses unchanged and leaves schema fields null', () {
      final q = QuestionModel.fromJson(const {
        'id': 'PHY-0001',
        'subject': 'Physics',
        'branch': 'Mechanics',
        'chapter': 'Laws of Motion',
        'coreConcept': 'Newton\'s second law',
        'questionType': 'Application',
        'difficulty': 'Medium',
        'question': 'A body of mass 2 kg accelerates at 3 m/s^2. Find F.',
        'options': ['4 N', '5 N', '6 N', '7 N'],
        'correctAnswer': 2,
        'explanation': 'F = ma = 2 x 3 = 6 N.',
        'sourcePattern': 'Standard',
        'timeLimitSeconds': 60,
      });

      expect(q.isSchemaFormat, isFalse);
      expect(q.correctAnswer, 2);
      expect(q.timeLimitSeconds, 60);
      expect(q.ncertClass, isNull);
      expect(q.topic, isNull);
      expect(q.bloomLevel, isNull);
      expect(q.commonWrongReasoning, isNull);
      expect(q.neetPyqYear, isNull);
    });
  });

  group('QuestionModel.fromJson — schema format (QUESTION_SCHEMA.md)', () {
    // The full example from QUESTION_SCHEMA.md.
    const schemaExample = {
      'id': 'BIO-1042',
      'subject': 'Biology',
      'chapter': 'Human Reproduction',
      'ncert_class': 12,
      'topic': 'Spermatogenesis',
      'difficulty': 'Medium',
      'bloom_level': 'application',
      'question_text':
          'During spermatogenesis, a primary spermatocyte undergoes meiosis I to form which of the following?',
      'options': [
        'Two secondary spermatocytes',
        'Four spermatids directly',
        'One secondary spermatocyte and one polar body',
        'Two spermatogonia',
      ],
      'correct_option': 'A',
      'explanation': 'Meiosis I is a reductional division.',
      'common_wrong_reasoning': {
        'B': 'skips a step',
        'C': 'confuses spermatogenesis with oogenesis',
        'D': 'confuses meiosis with earlier mitotic proliferation',
      },
      'neet_pyq_year': [2021],
      'avg_time_seconds': 75,
      'diagram': null,
    };

    test('maps correct_option letter to 0-based index', () {
      final q = QuestionModel.fromJson(schemaExample);
      expect(q.isSchemaFormat, isTrue);
      expect(q.correctAnswer, 0); // 'A' -> 0
    });

    test('derives app-side fields, surfaces schema fields additively', () {
      final q = QuestionModel.fromJson(schemaExample);
      expect(q.question, schemaExample['question_text']);
      expect(q.coreConcept, 'Spermatogenesis');
      expect(q.chapter, 'Human Reproduction');
      expect(q.branch, 'Class 12');
      expect(q.ncertClass, 12);
      expect(q.topic, 'Spermatogenesis');
      expect(q.bloomLevel, 'application');
      expect(q.questionType, 'Application');
      expect(q.commonWrongReasoning, isNotNull);
      expect(q.commonWrongReasoning!['B'], 'skips a step');
      expect(q.neetPyqYear, [2021]);
      expect(q.sourcePattern, 'NEET PYQ');
      expect(q.timeLimitSeconds, 75);
      expect(q.diagramId, isNull);
    });

    test('lowercase letter and index forms of correct_option both work', () {
      expect(
        QuestionModel.fromJson({
          ...schemaExample,
          'correct_option': 'd',
        }).correctAnswer,
        3,
      );
      expect(
        QuestionModel.fromJson({
          ...schemaExample,
          'correct_option': 2,
        }).correctAnswer,
        2,
      );
    });

    test('difficulty-based time defaults when avg_time_seconds is absent', () {
      int timeFor(String difficulty) => QuestionModel.fromJson({
            ...schemaExample,
            'difficulty': difficulty,
            'avg_time_seconds': null,
            'neet_pyq_year': null,
          }).timeLimitSeconds;

      expect(timeFor('Easy'), 45);
      expect(timeFor('Medium'), 75);
      expect(timeFor('Hard'), 110);
    });

    test('strips .png from diagram filenames', () {
      final q = QuestionModel.fromJson({
        ...schemaExample,
        'diagram': 'BIO-D07.png',
      });
      expect(q.diagramId, 'BIO-D07');
    });

    test('strips .svg from diagram filenames (merged demo bank convention)', () {
      final q = QuestionModel.fromJson({
        ...schemaExample,
        'diagram': 'D0001.svg',
      });
      expect(q.diagramId, 'D0001');
    });

    test('leaves extensionless diagram ids untouched', () {
      final q = QuestionModel.fromJson({
        ...schemaExample,
        'diagram': 'PHY-D25',
      });
      expect(q.diagramId, 'PHY-D25');
    });
  });

  group('QuestionModel.fromJson — real demo bank (schema fixtures)', () {
    test('every demo_set_qns question parses without throwing', () {
      final file = File('demo_set_qns/demo_questions_batch2.json');
      if (!file.existsSync()) {
        fail('demo bank fixture missing: ${file.path}');
      }
      final List questions =
          jsonDecode(file.readAsStringSync()) as List;
      expect(questions, isNotEmpty);

      for (final raw in questions) {
        final q = QuestionModel.fromJson(raw as Map<String, dynamic>);
        expect(q.options.length, 4, reason: '${q.id}: must have 4 options');
        expect(q.correctAnswer, inInclusiveRange(0, 3),
            reason: '${q.id}: correctAnswer out of range');
        expect(q.isSchemaFormat, isTrue, reason: '${q.id}: schema flag');
        expect(q.bloomLevel, isNotNull, reason: '${q.id}: bloom level');
        expect(q.timeLimitSeconds, greaterThan(0), reason: q.id);
      }
    });
  });
}
