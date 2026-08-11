class QuestionModel {
  final String id;
  final String subject;
  final String chapter;
  final String topic;
  final String difficulty;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;
  final int marks;

  const QuestionModel({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.marks,
  });
}