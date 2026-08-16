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

    final filtered = questions
        .where((question) => question.subject == subject)
        .toList();

    final diagramQuestions =
    filtered.where((question) => question.diagramId != null).toList();

    print('Repository: total questions = ${questions.length}');
    print('Repository: requested subject = "$subject"');
    print('Repository: filtered questions = ${filtered.length}');
    print('Repository: diagram questions = ${diagramQuestions.length}');

    if (diagramQuestions.isNotEmpty) {
      print(
        'Repository: first diagram = '
            '${diagramQuestions.first.id} -> '
            '${diagramQuestions.first.diagramId}',
      );
    }

    return filtered;
  }
}