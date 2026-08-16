class PracticeSession {
  final String subject;
  final int totalQuestions;

  int correctAnswers;
  int incorrectAnswers;
  int unansweredQuestions;

  final Map<int, int> selectedAnswers;

  // Keeps track of questions that have already been completed,
  // including questions that timed out.
  final Set<int> completedQuestions;

  PracticeSession({
    required this.subject,
    required this.totalQuestions,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.unansweredQuestions = 0,
  })  : selectedAnswers = {},
        completedQuestions = {};

  double get accuracy {
    if (totalQuestions == 0) return 0;

    return (correctAnswers / totalQuestions) * 100;
  }

  void recordAnswer({
    required int questionIndex,
    required int selectedAnswer,
    required int correctAnswer,
  }) {
    // Prevent the same question from being counted twice.
    if (completedQuestions.contains(questionIndex)) {
      return;
    }

    completedQuestions.add(questionIndex);
    selectedAnswers[questionIndex] = selectedAnswer;

    if (selectedAnswer == correctAnswer) {
      correctAnswers++;
    } else {
      incorrectAnswers++;
    }
  }

  void recordTimeout({
    required int questionIndex,
  }) {
    // Prevent the same question from being counted twice.
    if (completedQuestions.contains(questionIndex)) {
      return;
    }

    completedQuestions.add(questionIndex);
    unansweredQuestions++;
  }
}