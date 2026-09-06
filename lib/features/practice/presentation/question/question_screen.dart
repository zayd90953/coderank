import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/back_button_to_home.dart';
import '../../data/question_repository.dart';
import '../../models/question_model.dart';
import '../../models/practice_session.dart';
import '../results/results_screen.dart';

class QuestionScreen extends StatefulWidget {
  final String subject;
  final int questionCount;
  final String difficulty;
  final int? timeLimit;

  const QuestionScreen({
    super.key,
    required this.subject,
    this.questionCount = 10,
    this.difficulty = 'Mixed',
    this.timeLimit = 60,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int currentQuestion = 0;
  int? selectedAnswer;
  bool answered = false;

  List<QuestionModel> questions = [];
  bool isLoading = true;
  String? errorMessage;

  late PracticeSession session;

  Timer? _timer;
  int timeRemaining = 60;

  final QuestionRepository _repository = QuestionRepository();

  @override
  void initState() {
    super.initState();

    session = PracticeSession(
      subject: widget.subject,
      totalQuestions: 0,
    );

    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final loadedQuestions =
      await _repository.getQuestionsBySubject(widget.subject);

      if (!mounted) return;

      // Filter by difficulty.
      List<QuestionModel> filteredQuestions;

      if (widget.difficulty == 'Mixed') {
        filteredQuestions = List<QuestionModel>.from(loadedQuestions);
      } else {
        filteredQuestions = loadedQuestions
            .where(
              (question) =>
          question.difficulty.toLowerCase() ==
              widget.difficulty.toLowerCase(),
        )
            .toList();
      }

      // Randomize the questions.
      filteredQuestions.shuffle(Random());

      // Limit the number of questions.
      if (filteredQuestions.length > widget.questionCount) {
        filteredQuestions =
            filteredQuestions.take(widget.questionCount).toList();
      }

      setState(() {
        questions = filteredQuestions;

        session = PracticeSession(
          subject: widget.subject,
          totalQuestions: filteredQuestions.length,
        );

        isLoading = false;
      });

      if (questions.isNotEmpty && widget.timeLimit != null) {
        _startTimer();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();

    if (questions.isEmpty || widget.timeLimit == null) {
      return;
    }

    timeRemaining = widget.timeLimit!;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (!mounted) return;

        if (timeRemaining > 0) {
          setState(() {
            timeRemaining--;
          });
        } else {
          timer.cancel();
          _timeExpired();
        }
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _retryLoading() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    _loadQuestions();
  }

  void _timeExpired() {
    if (answered) return;

    setState(() {
      answered = true;

      session.recordTimeout(
        questionIndex: currentQuestion,
      );
    });
  }

  void _checkAnswer() {
    if (selectedAnswer == null || questions.isEmpty || answered) {
      return;
    }

    _stopTimer();

    final correctAnswer = questions[currentQuestion].correctAnswer;

    setState(() {
      answered = true;

      session.recordAnswer(
        questionIndex: currentQuestion,
        selectedAnswer: selectedAnswer!,
        correctAnswer: correctAnswer,
      );
    });
  }

  void _nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });

      if (widget.timeLimit != null) {
        _startTimer();
      }
    } else {
      _stopTimer();
      _showResults();
    }
  }

  void _showResults() {
    // P4-REGRESSION #3: use push so the device back from results pops to
    // the (just-completed) question screen, and the question screen's own
    // back returns to setup. pushReplacement would leave no route to pop.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          session: session,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButtonToHome(),
          title: Text(
            widget.subject,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: palette.primary,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButtonToHome(),
          title: Text(
            widget.subject,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Unable to load questions.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _retryLoading,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Retry",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButtonToHome(),
          title: Text(
            widget.subject,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No ${widget.difficulty.toLowerCase()} questions are available for ${widget.subject}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    final question = questions[currentQuestion];
    final options = question.options;
    final correctAnswer = question.correctAnswer;

    final progress =
        (currentQuestion + 1) / questions.length;

    final timerIsLow =
        widget.timeLimit != null && timeRemaining <= 10;

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

      leading: const BackButtonToHome(),

        title: Text(
          widget.subject,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Question ${currentQuestion + 1} of ${questions.length}",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  "${(progress * 100).round()}%",
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                AppColors.border,
                valueColor:
                AlwaysStoppedAnimation<Color>(
                  palette.primary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // TIMER
            if (widget.timeLimit != null)
              Row(
                mainAxisAlignment:
                MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: timerIsLow
                        ? AppColors.error
                        : palette.primary,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    "${timeRemaining}s",
                    style: TextStyle(
                      color: timerIsLow
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // QUESTION
            Text(
              question.question.replaceFirst(
                RegExp(
                  r'^\[See diagram [^\]]+\]\s*',
                ),
                '',
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),

            // DIAGRAM
            if (question.diagramId != null) ...[
              const SizedBox(height: 20),

              ClipRRect(
                borderRadius:
                BorderRadius.circular(16),

                child: Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding:
                  const EdgeInsets.all(12),

                  child: Image.asset(
                    'assets/practice/diagrams/${question.diagramId}.png',

                    fit: BoxFit.contain,

                    errorBuilder:
                        (context, error, stackTrace) {
                      return const Padding(
                        padding:
                        EdgeInsets.all(20),
                        child: Text(
                          'Diagram unavailable',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            color:
                            AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // OPTIONS
            ...List.generate(
              options.length,
                  (index) {
                final isSelected =
                    selectedAnswer == index;

                final isCorrect =
                    answered &&
                        index == correctAnswer;

                final isWrong =
                    answered &&
                        isSelected &&
                        !isCorrect;

                return Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child: InkWell(
                    onTap: answered
                        ? null
                        : () {
                      setState(() {
                        selectedAnswer =
                            index;
                      });
                    },

                    borderRadius:
                    BorderRadius.circular(16),

                    child: Container(
                      width: double.infinity,

                      padding:
                      const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.success
                            .withValues(
                          alpha: 0.08,
                        )
                            : isWrong
                            ? AppColors.error
                            .withValues(
                          alpha: 0.08,
                        )
                            : isSelected
                            ? palette
                            .primary
                            .withValues(
                          alpha: 0.08,
                        )
                            : AppColors.surface,

                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),

                        border: Border.all(
                          color: isCorrect
                              ? AppColors.success
                              : isWrong
                              ? AppColors.error
                              : isSelected
                              ? palette
                              .primary
                              : AppColors.border,

                          width: isSelected ||
                              isCorrect ||
                              isWrong
                              ? 1.5
                              : 1,
                        ),
                      ),

                      child: Row(
                        children: [

                          Container(
                            width: 38,
                            height: 38,
                            alignment:
                            Alignment.center,

                            decoration:
                            BoxDecoration(
                              color: isCorrect
                                  ? AppColors.success
                                  : isWrong
                                  ? AppColors.error
                                  : isSelected
                                  ? palette
                                  .primary
                                  : AppColors.surfaceElevated,

                              shape:
                              BoxShape.circle,
                            ),

                            child: Text(
                              String.fromCharCode(
                                65 + index,
                              ),

                              style: TextStyle(
                                color: isSelected ||
                                    isCorrect ||
                                    isWrong
                                    ? Colors.white
                                    : AppColors
                                    .text,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Text(
                              options[index],
                              style:
                              const TextStyle(
                                color:
                                AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),

                          if (isCorrect)
                            const Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                              AppColors.success,
                            ),

                          if (isWrong)
                            const Icon(
                              Icons
                                  .cancel_rounded,
                              color: AppColors.error,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // EXPLANATION / TIMEOUT
            if (answered)
              Container(
                width: double.infinity,

                padding:
                const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: selectedAnswer ==
                      correctAnswer
                      ? AppColors.success
                      .withValues(
                    alpha: 0.08,
                  )
                      : AppColors.error.withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Text(
                  selectedAnswer ==
                      correctAnswer
                      ? "Correct! ${question.explanation}"
                      : selectedAnswer == null
                      ? "Time's up! ${question.explanation}"
                      : "Not quite. ${question.explanation}",

                  style: TextStyle(
                    color: selectedAnswer ==
                        correctAnswer
                        ? AppColors.success
                        : AppColors.error,

                    fontSize: 14,
                    height: 1.4,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton(
                onPressed: answered
                    ? _nextQuestion
                    : selectedAnswer == null
                    ? null
                    : _checkAnswer,

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  palette.primary,

                  disabledBackgroundColor:
                  palette.primary
                      .withValues(
                    alpha: 0.35,
                  ),

                  foregroundColor:
                  Colors.white,

                  elevation: 0,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                ),

                child: Text(
                  answered
                      ? "Next Question"
                      : "Check Answer",

                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
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

