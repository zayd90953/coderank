class QuestionModel {
  final String id;
  final String subject;
  final String branch;
  final String chapter;
  final String coreConcept;
  final String questionType;
  final String difficulty;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final String sourcePattern;
  final String? diagramId;
  final int timeLimitSeconds;

  // R-1: schema-format extensions (null for app-format questions).

  /// True when parsed from the QUESTION_SCHEMA.md format.
  final bool isSchemaFormat;

  /// NCERT class (11 or 12) the chapter belongs to. Schema format only.
  final int? ncertClass;

  /// Sub-topic within the chapter. Schema format only.
  final String? topic;

  /// recall / application / analysis. Schema format only.
  final String? bloomLevel;

  /// Per wrong option letter: the likely misconception behind picking it.
  /// Schema format only; keys are option letters ("A"..."D").
  final Map<String, String>? commonWrongReasoning;

  /// Years this concept appeared in a real NEET paper. Schema format only.
  final List<int>? neetPyqYear;

  const QuestionModel({
    required this.id,
    required this.subject,
    required this.branch,
    required this.chapter,
    required this.coreConcept,
    required this.questionType,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.sourcePattern,
    this.isSchemaFormat = false,
    this.ncertClass,
    this.topic,
    this.bloomLevel,
    this.commonWrongReasoning,
    this.neetPyqYear,
    this.diagramId,
    this.timeLimitSeconds = 60,
  });

  /// R-1: parses both bank formats. App format (the original bank): keys
  /// `question`, `correctAnswer` (0-based index), `coreConcept`,
  /// `questionType`, `branch`, `sourcePattern`, `timeLimitSeconds`,
  /// `diagramId`. Schema format (QUESTION_SCHEMA.md, used by the demo bank
  /// and all future tagging): keys `question_text`, `correct_option`
  /// (letter A-D), `topic`, `bloom_level`, `ncert_class`,
  /// `common_wrong_reasoning`, `neet_pyq_year`, `avg_time_seconds`,
  /// `diagram`. Schema questions get their app-side fields derived (branch
  /// from NCERT class, questionType from bloom level, sourcePattern from
  /// PYQ years, time limit from difficulty defaults) so the rest of the app
  /// needs no format awareness. The schema-only fields are surfaced
  /// additively and are null for app-format questions.
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('question_text')) return _fromSchemaJson(json);
    return _fromAppJson(json);
  }

  // -- Schema format (QUESTION_SCHEMA.md): derives the app-side fields. --

  static QuestionModel _fromSchemaJson(Map<String, dynamic> json) {
    final options = List<String>.from(json['options'] as List);
    final difficulty = json['difficulty'] as String;

    // `correct_option` is the letter A-D; map to the app's 0-based index.
    final correctOptionRaw = json['correct_option'];
    final int correctAnswer;
    if (correctOptionRaw is int) {
      correctAnswer = correctOptionRaw;
    } else {
      final letter =
          (correctOptionRaw as String).trim().toUpperCase().substring(0, 1);
      correctAnswer = letter.codeUnitAt(0) - 65; // 'A' -> 0
    }

    // Diagram assets are referenced without the extension in the app
    // ('${question.diagramId}.png'), so strip a '.png' suffix if tagged.
    final diagram = json['diagram'] as String?;
    final diagramId =
        (diagram != null && diagram.toLowerCase().endsWith('.png'))
            ? diagram.substring(0, diagram.length - 4)
            : diagram;

    final pyqYears = json['neet_pyq_year'] != null
        ? List<int>.from(json['neet_pyq_year'] as List)
        : null;

    return QuestionModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      branch: 'Class ${json['ncert_class']}',
      chapter: json['chapter'] as String,
      coreConcept: json['topic'] as String,
      questionType: _bloomToQuestionType(json['bloom_level'] as String?),
      difficulty: difficulty,
      question: json['question_text'] as String,
      options: options,
      correctAnswer: correctAnswer,
      explanation: json['explanation'] as String,
      // The original bank distinguishes e.g. PYQ-sourced questions; the
      // schema equivalent is the neet_pyq_year tag.
      sourcePattern:
          (pyqYears != null && pyqYears.isNotEmpty) ? 'NEET PYQ' : 'Standard',
      isSchemaFormat: true,
      ncertClass: json['ncert_class'] as int?,
      topic: json['topic'] as String?,
      bloomLevel: json['bloom_level'] as String?,
      commonWrongReasoning: json['common_wrong_reasoning'] != null
          ? Map<String, String>.from(json['common_wrong_reasoning'] as Map)
          : null,
      neetPyqYear: pyqYears,
      diagramId: diagramId,
      timeLimitSeconds:
          json['avg_time_seconds'] as int? ?? _defaultTimeFor(difficulty),
    );
  }

  // avg_time_seconds defaults per QUESTION_SCHEMA.md when untagged:
  // Easy 45s, Medium 75s, Hard 110s.
  static int _defaultTimeFor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 45;
      case 'hard':
        return 110;
      default:
        return 75; // Medium
    }
  }

  static String _bloomToQuestionType(String? bloom) {
    switch (bloom) {
      case 'recall':
        return 'Recall';
      case 'analysis':
        return 'Analysis';
      default:
        return 'Application';
    }
  }

  // -- App format (original bank): behavior unchanged. --

  static QuestionModel _fromAppJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      subject: json['subject'] as String,
      branch: json['branch'] as String,
      chapter: json['chapter'] as String,
      coreConcept: json['coreConcept'] as String,
      questionType: json['questionType'] as String,
      difficulty: json['difficulty'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String,
      sourcePattern: json['sourcePattern'] as String,
      diagramId: json['diagramId'] as String?,
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 60,
    );
  }
}