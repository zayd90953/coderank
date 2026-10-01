import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/services/weak_area_tracking_service.dart';
import '../../../shared/utils/app_haptics.dart';
import '../../../shared/utils/numeric_display_formatter.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../../shared/widgets/explanation_card.dart';
import '../../../shared/widgets/question_diagram.dart';
import '../../practice/models/practice_session.dart';
import '../../practice/models/question_model.dart';
import '../data/diagnostic_test_builder.dart';
import 'diagnostic_results_screen.dart';

/// R-4: the diagnostic runner.
///
/// Deliberately UNLIKE the other runners in one respect: no per-question
/// timer — a check-up should measure knowledge, not speed pressure.
///
/// Recording policy (documented decision): the diagnostic does NOT go
/// through UserProgressService.recordSession — that would add a fake
/// "Diagnostic" subject key to subjectStats and pollute the analytics
/// mastery cards. Instead it feeds the weak-area engine (R-3) and awards
/// a flat +20 completion XP via addXp, then stamps the per-subject
/// diagnostic date and pushes the chapter-breakdown results.
class DiagnosticQuestionScreen extends StatefulWidget {
  final String subject;

  /// Test seam (and future pre-scripted diagnostics): when provided, the
  /// runner uses exactly this set instead of drawing from the builder.
  /// Production callers leave it null.
  final List<QuestionModel>? questionsOverride;

  const DiagnosticQuestionScreen({
    super.key,
    required this.subject,
    this.questionsOverride,
  });

  @override
  State<DiagnosticQuestionScreen> createState() =>
      _DiagnosticQuestionScreenState();
}

class _DiagnosticQuestionScreenState extends State<DiagnosticQuestionScreen> {
  static const int _completionBonusXp = 20;

  List<QuestionModel> questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  int _currentQuestion = 0;
  int? _selectedAnswer;
  bool _answered = false;

  // Constructed after the set loads (totalQuestions is final).
  late PracticeSession _session;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final set = widget.questionsOverride ??
        await DiagnosticTestBuilder.buildSet(widget.subject);
    if (!mounted) return;
    setState(() {
      questions = set;
      _session = PracticeSession(
        subject: 'Diagnostic — ${widget.subject}',
        totalQuestions: set.length,
      );
      _isLoading = false;
    });
  }

  void _checkAnswer() {
    if (_selectedAnswer == null || _answered || questions.isEmpty) return;
    // _session is ready whenever questions are rendered (loading guard).
    final correctAnswer = questions[_currentQuestion].correctAnswer;
    // A-10: tactile verdict — the reveal is animated, the hand gets a say too.
    _selectedAnswer == correctAnswer
        ? AppHaptics.success()
        : AppHaptics.error();
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
    if (_currentQuestion < questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Feed the weak-area engine (one batched write; timeouts miss).
      await WeakAreaTrackingService.instance.recordQuestionOutcomes([
        for (var i = 0; i < questions.length; i++)
          if (_session.completedQuestions.contains(i))
            (
              question: questions[i],
              isCorrect:
                  _session.selectedAnswers[i] == questions[i].correctAnswer,
            ),
      ]);
      // 2. Stamp the per-subject diagnostic date.
      await WeakAreaTrackingService.instance
          .markDiagnosticCompleted(widget.subject);
      // 3. Flat completion XP (no subject-stat pollution — see class doc).
      await UserProgressService.instance.addXp(_completionBonusXp);
    } catch (_) {
      // Persistence must never block the results screen.
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosticResultsScreen(
          subject: widget.subject,
          session: _session,
          questions: questions,
          bonusXp: _completionBonusXp,
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      // Defensive: the intro guards this, but a mid-session bank change
      // must not dead-end silently either.
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButtonToHome(),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No questions available for this subject right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final question = questions[_currentQuestion];
    final progress = (_currentQuestion) / questions.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          'Check-up ${_currentQuestion + 1}/${questions.length}',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: scheme.outline,
            valueColor: AlwaysStoppedAnimation<Color>(
              ColorPaletteController.instance.current.primary,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      question.difficulty,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    formatNumericDisplay(question.question),
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  // Diagram (SVG or PNG via shared widget; soft-fails if missing)
                  if (question.diagramId != null) ...[
                    const SizedBox(height: 16),
                    QuestionDiagram(diagramId: question.diagramId),
                  ],
                  const SizedBox(height: 24),
                  ...List.generate(question.options.length, (i) {
                    final isSelected = _selectedAnswer == i;
                    final isCorrect = i == question.correctAnswer;
                    final revealed = _answered;

                    Color bg = scheme.surfaceContainer;
                    Color border = scheme.outline;
                    Color text = scheme.onSurface;

                    if (revealed && isCorrect) {
                      bg = AppColors.success.withValues(alpha: 0.14);
                      border = AppColors.success;
                      text = AppColors.success;
                    } else if (revealed && isSelected && !isCorrect) {
                      bg = AppColors.error.withValues(alpha: 0.12);
                      border = AppColors.error;
                      text = AppColors.error;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _answered
                              ? null
                              : () => setState(() => _selectedAnswer = i),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: border, width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    formatNumericDisplay(question.options[i]),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: revealed && isCorrect
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: text,
                                    ),
                                  ),
                                ),
                                if (revealed && isCorrect)
                                  Icon(Icons.check_circle_rounded,
                                      color: AppColors.success, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_answered) ...[
                    const SizedBox(height: 6),
                    // R-7: teaching moment inside the check-up too —
                    // verdict, explanation, and the misconception
                    // callout when schema tagging provides one.
                    ExplanationCard(
                      selectedOptionIndex: _selectedAnswer,
                      correctOptionIndex: question.correctAnswer,
                      explanation: question.explanation,
                      commonWrongReasoning: question.commonWrongReasoning,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _answered ? scheme.primary : scheme.surfaceContainerHighest,
                  foregroundColor:
                      _answered ? scheme.onPrimary : scheme.onSurfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _answered ? _nextQuestion : _checkAnswer,
                child: Text(
                  !_answered
                      ? 'Check'
                      : _currentQuestion == questions.length - 1
                          ? 'See my map'
                          : 'Next',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
