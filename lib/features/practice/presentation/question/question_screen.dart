import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/question_data.dart';
import '../../models/question_model.dart';
import '../results/results_screen.dart';

class QuestionScreen extends StatefulWidget {
  final String subject;

  const QuestionScreen({
    super.key,
    required this.subject,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int currentQuestion = 0;
  int? selectedAnswer;
  bool answered = false;
  int score = 0;

  late final List<QuestionModel> questions;

  @override
  void initState() {
    super.initState();

    if (widget.subject == "Physics") {
      questions = QuestionData.physicsQuestions;
    } else if (widget.subject == "Chemistry") {
      questions = QuestionData.chemistryQuestions;
    } else if (widget.subject == "Biology") {
      questions = QuestionData.biologyQuestions;
    } else {
      questions = [];
    }
  }

  void _checkAnswer() {
    if (selectedAnswer == null) return;

    final correctAnswer = questions[currentQuestion].correctAnswer;

    setState(() {
      answered = true;

      if (selectedAnswer == correctAnswer) {
        score++;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          subject: widget.subject,
          score: score,
          totalQuestions: questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];
    final options = question.options;
    final correctAnswer = question.correctAnswer;
    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.text,
        ),
        title: Text(
          widget.subject,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number and percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Question ${currentQuestion + 1} of ${questions.length}",
                  style: TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${(progress * 100).round()}%",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE6E2EE),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Question
            Text(
              question.question,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 21,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 28),

            // Answer options
            ...List.generate(
              options.length,
                  (index) {
                final isSelected = selectedAnswer == index;
                final isCorrect = answered && index == correctAnswer;
                final isWrong = answered && isSelected && !isCorrect;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: answered
                        ? null
                        : () {
                      setState(() {
                        selectedAnswer = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withValues(alpha: 0.08)
                            : isWrong
                            ? Colors.red.withValues(alpha: 0.08)
                            : isSelected
                            ? AppColors.primary.withValues(
                          alpha: 0.08,
                        )
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green
                              : isWrong
                              ? Colors.red
                              : isSelected
                              ? AppColors.primary
                              : const Color(0xFFE7E3F0),
                          width:
                          isSelected || isCorrect || isWrong ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Option letter
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green
                                  : isWrong
                                  ? Colors.red
                                  : isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFF1EFF6),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                color: isSelected || isCorrect || isWrong
                                    ? Colors.white
                                    : AppColors.text,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Option text
                          Expanded(
                            child: Text(
                              options[index],
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Correct / wrong icon
                          if (isCorrect)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green,
                            ),

                          if (isWrong)
                            const Icon(
                              Icons.cancel_rounded,
                              color: Colors.red,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Explanation
            if (answered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedAnswer == correctAnswer
                      ? Colors.green.withValues(alpha: 0.08)
                      : Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  selectedAnswer == correctAnswer
                      ? "Correct! ${question.explanation}"
                      : "Not quite. ${question.explanation}",
                  style: TextStyle(
                    color: selectedAnswer == correctAnswer
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Check / Next button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: selectedAnswer == null
                    ? null
                    : answered
                    ? _nextQuestion
                    : _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  answered ? "Next Question" : "Check Answer",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}