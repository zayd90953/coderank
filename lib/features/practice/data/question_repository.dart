import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/question_model.dart';

class QuestionRepository {
  static const String _questionsPath =
      'lib/features/practice/data/questions.json';

  Future<List<QuestionModel>> _loadQuestions() async {
    final jsonString = await rootBundle.loadString(_questionsPath);

    final List<dynamic> jsonData = jsonDecode(jsonString);

    return jsonData
        .map(
          (json) => QuestionModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  Future<List<QuestionModel>> getQuestionsBySubject(
      String subject,
      ) async {
    final questions = await _loadQuestions();

    return questions
        .where((question) => question.subject == subject)
        .toList();
  }

  /// Return every question in the bank, regardless of subject.
  Future<List<QuestionModel>> getAllQuestions() async {
    return _loadQuestions();
  }

  /// Compose a NEET-style mock test paper: `[Physics] [Chemistry] [Biology]`,
  /// in that order, with each section capped at the requested count.
  ///
  /// If a subject's pool has fewer questions than [physicsCount] / [chemCount]
  /// / [bioCount], the available questions are returned and the section is
  /// simply shorter. The total length is therefore bounded by the size of the
  /// underlying pool, never inflated with duplicates.
  Future<List<QuestionModel>> getMockTestQuestions({
    required int physicsCount,
    required int chemCount,
    required int bioCount,
  }) async {
    final all = await _loadQuestions();

    final physics = all
        .where((q) => q.subject == 'Physics')
        .take(physicsCount)
        .toList();
    final chemistry = all
        .where((q) => q.subject == 'Chemistry')
        .take(chemCount)
        .toList();
    final biology = all
        .where((q) => q.subject == 'Biology')
        .take(bioCount)
        .toList();

    return [...physics, ...chemistry, ...biology];
  }
}