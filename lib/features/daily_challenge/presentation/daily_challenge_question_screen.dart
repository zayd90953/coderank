import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/services/weak_area_tracking_service.dart';
import '../../../shared/utils/numeric_display_formatter.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../../shared/widgets/explanation_card.dart';
import '../../practice/models/practice_session.dart';
import '../../practice/models/question_model.dart';
import 'daily_challenge_results_screen.dart';

/// A-3: the actual 10-question runner for the Daily NEET Challenge.
///
/// Receives a pre-built [questions] list (the launcher fetches it from
/// [QuestionRepository.getDailyChallengeQuestions] for the current date,
/// so every user gets the same 10 questions for the same calendar day).
///
/// On Q 10's submission, this screen:
///   1. Builds a [PracticeSession] (subject = "Daily Challenge", isDailyChallenge = true).
///   2. Calls [UserProgressService.recordSession] for per-correct XP and stat updates.
///   3. Calls [UserProgressService.addXp] with a +50 completion bonus.
///   4. Calls [UserProgressService.markDailyChallengeCompleted] to stamp the
///      per-day lock and accumulate the daily XP into the running total.
///   5. Pushes [DailyChallengeResultsScreen] for the summary.
class DailyChallengeQuestionScreen extends StatefulWidget {
  final List<QuestionModel> questions;

  const DailyChallengeQuestionScreen({
    super.key,
    required this.questions,
  });

  @override
  State<DailyChallengeQuestionScreen> createState() =>
      _DailyChallengeQuestionScreenState();
}

class _DailyChallengeQuestionScreenState
    extends State<DailyChallengeQuestionScreen> {
  static const int _secondsPerQuestion = 45;
  static const int _completionBonusXp = 50;
  static const String _subject = 'Daily Challenge';

  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _isSubmitting = false;

  late final PracticeSession _session;

  Timer? _timer;
  int _timeRemaining = _secondsPerQuestion;

  @override
  void initState() {
    super.initState();
    _session = PracticeSession(
      subject: _subject,
      totalQuestions: widget.questions.length,
      isDailyChallenge: true,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeRemaining = _secondsPerQuestion;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_timeRemaining > 0) {
          setState(() {
            _timeRemaining--;
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

  void _timeExpired() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _session.recordTimeout(questionIndex: _currentQuestion);
    });
  }

  void _checkAnswer() {
    if (_selectedAnswer == null || _answered) return;
    _stopTimer();
    final correctAnswer = widget.questions[_currentQuestion].correctAnswer;
    setState(() {
      _answered = true;
      _session.recordAnswer(
        questionIndex: _currentQuestion,
        selectedAnswer: _selectedAnswer!,
        correctAnswer: correctAnswer,
      );
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentQuestion < widget.questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
      _startTimer();
    } else {
      _stopTimer();
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    int sessionXp = 0;
    try {
      sessionXp =
          await UserProgressService.instance.recordSession(_session);
      await UserProgressService.instance.addXp(_completionBonusXp);
      await UserProgressService.instance.markDailyChallengeCompleted(
        xpEarned: sessionXp + _completionBonusXp,
      );

      // R-3: weak-area tracking batch (a timeout counts as a miss).
      await WeakAreaTrackingService.instance.recordQuestionOutcomes([
        for (var i = 0; i < widget.questions.length; i++)
          if (_session.completedQuestions.contains(i))
            (
              question: widget.questions[i],
              isCorrect: _session.selectedAnswers[i] ==
                  widget.questions[i].correctAnswer,
            ),
      ]);
    } catch (_) {
      // Persistence must never block the results screen — mirrors the
      // mock-test and practice runners, which also swallow failures.
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DailyChallengeResultsScreen(
          session: _session,
          completionBonusXp: _completionBonusXp,
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
    final question = widget.questions[_currentQuestion];
    final options = question.options;
    final correctAnswer = question.correctAnswer;
    final progress =
        (_currentQuestion + 1) / widget.questions.length;
    final timerIsLow = _timeRemaining <= 10;
    final isLast = _currentQuestion == widget.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          'Daily NEET Challenge',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: question N/10 chip + percentage.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primarySubtle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Q ${_currentQuestion + 1} / ${widget.questions.length}",
                    style: TextStyle(
                      color: palette.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

            const SizedBox(height: 10),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.outline,
                valueColor:
                    AlwaysStoppedAnimation<Color>(palette.primary),
              ),
            ),

            const SizedBox(height: 12),

            // Timer.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: timerIsLow ? AppColors.error : palette.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  "${_timeRemaining}s",
                  style: TextStyle(
                    color: timerIsLow
                        ? AppColors.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Question text.
            Text(
              formatNumericDisplay(
                question.question.replaceFirst(
                  RegExp(r'^\[See diagram [^\]]+\]\s*'),
                  '',
                ),
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 21,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (question.diagramId != null) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/practice/diagrams/${question.diagramId}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Diagram unavailable',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Options.
            ...List.generate(
              options.length,
              (index) {
                final isSelected = _selectedAnswer == index;
                final isCorrect = _answered && index == correctAnswer;
                final isWrong =
                    _answered && isSelected && !isCorrect;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _answered
                        ? null
                        : () {
                            setState(() {
                              _selectedAnswer = index;
                            });
                          },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.success.withValues(alpha: 0.08)
                            : isWrong
                                ? AppColors.error.withValues(alpha: 0.08)
                                : isSelected
                                    ? palette.primary
                                        .withValues(alpha: 0.08)
                                    : Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.success
                              : isWrong
                                  ? AppColors.error
                                  : isSelected
                                      ? palette.primary
                                      : Theme.of(context).colorScheme.outline,
                          width: isSelected || isCorrect || isWrong
                              ? 1.5
                              : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? AppColors.success
                                  : isWrong
                                      ? AppColors.error
                                      : isSelected
                                          ? palette.primary
                                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                color: isSelected || isCorrect || isWrong
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              formatNumericDisplay(options[index]),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isCorrect)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                            ),
                          if (isWrong)
                            const Icon(
                              Icons.cancel_rounded,
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

            // Explanation (R-7: shared explanation card with the
            // misconception callout when schema tagging provides it).
            if (_answered)
              ExplanationCard(
                selectedOptionIndex: _selectedAnswer,
                correctOptionIndex: correctAnswer,
                explanation: question.explanation,
                commonWrongReasoning: question.commonWrongReasoning,
              ),

            const SizedBox(height: 20),

            // Bottom action button.
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : (_answered
                        ? _nextQuestion
                        : (_selectedAnswer == null ? null : _checkAnswer)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  disabledBackgroundColor:
                      palette.primary.withValues(alpha: 0.35),
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : Text(
                        _answered
                            ? (isLast ? "Finish" : "Next Question")
                            : "Check Answer",
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
