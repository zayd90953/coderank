import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/firestore_sync_service.dart';
import '../../../../shared/services/user_progress_service.dart';
import '../../../../shared/services/weak_area_tracking_service.dart';
import '../../../../shared/utils/app_haptics.dart';
import '../../../../shared/utils/numeric_display_formatter.dart';
import '../../../../shared/widgets/back_button_to_home.dart';
import '../../../../shared/widgets/explanation_card.dart';
import '../../../../shared/widgets/question_diagram.dart';
import '../../../../shared/utils/pacing_utils.dart';
import '../../data/question_repository.dart';
import '../../models/question_model.dart';
import '../../models/practice_session.dart';
import '../results/results_screen.dart';

class QuestionScreen extends StatefulWidget {
  final String subject;
  final int questionCount;
  final String difficulty;
  final int? timeLimit;

  /// R-5: optional chapter focus. When set, the session draws ONLY from
  /// this chapter (the weak-chapter drill recommendation routes here with
  /// the chapter payload). Null keeps the classic subject-wide draw.
  final String? chapter;

  /// Mistake review (M-7): when set, the session runs EXACTLY these
  /// questions (subject/difficulty/chapter/questionCount are ignored),
  /// and [subject] only labels the session. The regular per-session
  /// recording (XP, weak-area batch, cloud idempotency) applies as-is, so
  /// a later correct answer resolves the mistake in the R-3 memory.
  final List<QuestionModel>? questionsOverride;

  const QuestionScreen({
    super.key,
    required this.subject,
    this.questionCount = 10,
    this.difficulty = 'Mixed',
    this.timeLimit = 60,
    this.chapter,
    this.questionsOverride,
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

  /// Guards against double-recording: returning from the results screen
  /// (device back) and tapping "Next Question" re-enters [_showResults],
  /// and the session must only be persisted once.
  bool _resultsRecorded = false;

  /// Cloud-submission idempotency key. Generated lazily exactly once per
  /// session instance, so a retried submission of the same session reuses
  /// the same ID and the server dedupes on users/{uid}/sessions/{sessionId}.
  String? _cloudSessionId;

  late PracticeSession session;

  Timer? _timer;
  int timeRemaining = 60;

  // R-8: per-question pacing — how long THIS question has been on
  // screen, and how the answer compared to its expected pace. Tracked
  // even in untimed sessions (pacing is about the question, not the
  // session clock). Timed-out questions are also recorded for stats.
  final Stopwatch _questionStopwatch = Stopwatch();
  final List<bool> _slowAnswers = [];

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
      // Mistake review (M-7): an exact question list overrides every
      // other selection parameter.
      if (widget.questionsOverride != null) {
        final picked = List<QuestionModel>.from(widget.questionsOverride!);
        if (picked.isEmpty) {
          // Defensive: nothing left to review — show the standard retry
          // error state rather than an empty session.
          if (!mounted) return;
          setState(() {
            isLoading = false;
            errorMessage = 'No questions to review.';
          });
          return;
        }
        picked.shuffle(Random());
        setState(() {
          questions = picked;
          session = PracticeSession(
            subject: widget.subject,
            totalQuestions: picked.length,
          );
          isLoading = false;
        });
        _restartPaceClock();
        return; // review sessions are untimed — no countdown pressure
      }

      // R-5: chapter-focused drill vs classic subject-wide draw.
      final loadedQuestions = widget.chapter != null
          ? await _repository.getQuestionsByChapter(
              widget.subject, widget.chapter!)
          : await _repository.getQuestionsBySubject(widget.subject);

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

      _restartPaceClock(); // R-8: first question's clock starts now
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

  /// R-8: restarts the per-question pacing clock. Runs for timed AND
  /// untimed sessions — pacing is about the question, not the clock.
  void _restartPaceClock() {
    _questionStopwatch
      ..reset()
      ..start();
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
    _questionStopwatch.stop();
  }

  /// R-8: closes the stopwatch for the current question and flags the
  /// answer if it blew past the question's expected pace.
  void _recordPace() {
    _questionStopwatch.stop();
    final seconds = _questionStopwatch.elapsed.inSeconds;
    final isSlow = questions.isNotEmpty &&
        currentQuestion < questions.length &&
        PaceUtils.isSlowAnswer(questions[currentQuestion], seconds);
    _slowAnswers.add(isSlow);
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
      // R-8: a session-clock expiry is the ultimate slow answer.
      _recordPace();
    });
  }

  void _checkAnswer() {
    if (selectedAnswer == null || questions.isEmpty || answered) {
      return;
    }

    _stopTimer();
    _recordPace(); // R-8: capture this answer's pace before moving on

    final correctAnswer = questions[currentQuestion].correctAnswer;

    // A-10: tactile verdict — the reveal is animated, the hand gets a say too.
    selectedAnswer == correctAnswer
        ? AppHaptics.success()
        : AppHaptics.error();

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
      _restartPaceClock(); // R-8: fresh clock for the next question

      if (widget.timeLimit != null) {
        _startTimer();
      }
    } else {
      _stopTimer();
      _showResults();
    }
  }

  Future<void> _showResults() async {
    int xpEarned = 0;
    // A-9: capture the tier before/after recording so the results screen
    // can stage a full-screen tier-up moment when this session crosses a
    // tier boundary (XP only ever grows, so any change is an upgrade).
    String? tierUp;

    // Record the finished session exactly once. Back-navigation from the
    // results screen re-enters this method, so without the guard every
    // revisit would re-count XP, subject stats and history.
    if (!_resultsRecorded) {
      _resultsRecorded = true;
      final tierBefore = UserProgressService.instance.current.tier;
      try {
        xpEarned = await UserProgressService.instance.recordSession(session);
      } catch (_) {
        // Persistence must never block the results screen — mirrors the
        // mock-test runner, which also swallows recordSession failures.
        xpEarned = 0;
      }
      final tierAfter = UserProgressService.instance.current.tier;
      if (tierAfter != tierBefore) tierUp = tierAfter;

      // R-3: feed per-question outcomes to weak-area tracking — one batch
      // per session; a timeout counts as a miss. Never blocks the results
      // screen (mirrors recordSession's swallowed-failure posture).
      try {
        await WeakAreaTrackingService.instance.recordQuestionOutcomes([
          for (var i = 0; i < questions.length; i++)
            if (session.completedQuestions.contains(i))
              (
                question: questions[i],
                isCorrect: session.selectedAnswers[i] ==
                    questions[i].correctAnswer,
              ),
        ]);
      } catch (_) {}

      // Cloud verification (normal practice only): fire-and-forget — never
      // blocks the results screen and never touches local progress. The
      // local XP above is the offline ledger; the server keeps the
      // authoritative one. Skipped when signed out.
      unawaited(_submitCloudVerification());
    }

    if (!mounted) return;

    // R-8: how many answered questions blew past their expected pace.
    final slowCount = _slowAnswers.where((s) => s).length;

    // P4-REGRESSION #3: use push so the device back from results pops to
    // the (just-completed) question screen, and the question screen's own
    // back returns to setup. pushReplacement would leave no route to pop.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          session: session,
          xpEarned: xpEarned,
          tierUp: tierUp,
          questionCount: widget.questionCount,
          difficulty: widget.difficulty,
          timeLimit: widget.timeLimit,
          slowAnswerCount: slowCount,
        ),
      ),
    );
  }

  /// Submits the completed practice session for server-side verification.
  ///
  /// Contract notes:
  ///  * NORMAL PRACTICE ONLY — daily challenge, mock and diagnostic flows
  ///    are intentionally NOT submitted here. The server supports them,
  ///    but this screen must never claim another session kind.
  ///  * Answers are keyed by question ID (never an index).
  ///  * Only questions actually completed are submitted, each in exactly
  ///    one state (answered or timed out) as the server contract requires.
  ///  * One stable sessionId per session instance → a network retry of the
  ///    same session can never double-award: the server deduplicates on
  ///    users/{uid}/sessions/{sessionId} inside its transaction.
  ///  * The result — including the server-verified record — does NOT modify
  ///    local progress. Local XP was already recorded above. Any failure
  ///    (function unavailable, offline, signed out) simply leaves this as
  ///    an unverified local-only result and the app stays fully usable.
  Future<void> _submitCloudVerification() async {
    // Signed out (or tests): nothing to verify against.
    if (UserProgressService.instance.userId == null) return;

    // Belt-and-braces: this screen is practice-only.
    if (session.isDailyChallenge) return;

    final completedIndexes = session.completedQuestions
        .where((i) => i >= 0 && i < questions.length)
        .toList();
    // Defensive: an empty session has nothing to verify.
    if (completedIndexes.isEmpty) return;

    try {
      final request = SessionSubmitRequest(
        sessionId: _cloudSessionId ??=
            DateTime.now().millisecondsSinceEpoch.toString(),
        sessionKind: 'practice',
        subject: widget.subject,
        questionIds: [for (final i in completedIndexes) questions[i].id],
        selectedAnswers: {
          for (final i in completedIndexes)
            if (session.selectedAnswers[i] != null)
              questions[i].id: session.selectedAnswers[i]!,
        },
        timedOutQuestionIds: {
          for (final i in completedIndexes)
            if (!session.selectedAnswers.containsKey(i)) questions[i].id,
        },
        timestamp: DateTime.now(),
      );

      final result =
          await FirestoreSyncService.instance.submitSession(request);
      if (!result.success) {
        // Unverified local-only result — keep the app fully usable.
        debugPrint(
          'Practice cloud verification unavailable: ${result.errorMessage}',
        );
      }
    } catch (e) {
      // submitSession only throws when no UID is set; guard above should
      // make this unreachable, but the results flow must never break.
      debugPrint('Practice cloud verification error: $e');
    }
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButtonToHome(),
          title: Text(
            widget.subject,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButtonToHome(),
          title: Text(
            widget.subject,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButtonToHome(),
          title: Text(
            widget.subject,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

      leading: const BackButtonToHome(),

        title: Text(
          widget.subject,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                Theme.of(context).colorScheme.outline,
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
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // QUESTION
            Text(
              formatNumericDisplay(
                question.question.replaceFirst(
                  RegExp(
                    r'^\[See diagram [^\]]+\]\s*',
                  ),
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

            // DIAGRAM (SVG or PNG via shared widget; soft-fails if missing)
            if (question.diagramId != null) ...[
              const SizedBox(height: 20),
              QuestionDiagram(diagramId: question.diagramId),
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

                    // A-9: AnimatedContainer — the green/red reveal on
                    // answering fades in instead of snapping.
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
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
                            : Theme.of(context).colorScheme.surfaceContainer,

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
                              : Theme.of(context).colorScheme.outline,

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
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,

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
                              formatNumericDisplay(options[index]),
                              style:
                              TextStyle(
                                color:
                                Theme.of(context).colorScheme.onSurface,
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

            // EXPLANATION / TIMEOUT (R-7: shared explanation card with
            // the misconception callout when schema tagging provides it)
            if (answered)
              ExplanationCard(
                selectedOptionIndex: selectedAnswer,
                correctOptionIndex: correctAnswer,
                explanation: question.explanation,
                commonWrongReasoning: question.commonWrongReasoning,
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

