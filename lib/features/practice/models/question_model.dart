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
    this.diagramId,
    this.timeLimitSeconds = 60,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
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