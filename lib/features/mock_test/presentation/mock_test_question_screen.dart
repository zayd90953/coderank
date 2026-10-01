import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../features/practice/models/question_model.dart';
import '../../../features/practice/models/practice_session.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/services/weak_area_tracking_service.dart';
import '../../../shared/utils/numeric_display_formatter.dart';
import '../../../shared/utils/pacing_utils.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../../shared/widgets/question_diagram.dart';
import 'mock_test_results_screen.dart';

/// The exam-style question screen for the Full-Length Mock Test.
///
/// Differences from the regular [QuestionScreen]:
/// - A **total** 3-hour countdown timer (not per-question).
/// - Questions are grouped by section (Physics → Chemistry → Biology).
/// - A scrollable **question palette** lets the student jump to any question.
/// - Students can **mark questions for review** (flag them for later).
/// - Submitting (or timer expiry) navigates to [MockTestResultsScreen].
class MockTestQuestionScreen extends StatefulWidget {
  final List<QuestionModel> questions;
  final int durationSeconds; // total exam duration

  const MockTestQuestionScreen({
    super.key,
    required this.questions,
    this.durationSeconds = 10800, // 3 hours
  });

  @override
  State<MockTestQuestionScreen> createState() => _MockTestQuestionScreenState();
}

class _MockTestQuestionScreenState extends State<MockTestQuestionScreen> {
  int _current = 0;

  /// selectedAnswers[i] = index of selected option, or null if skipped.
  late final List<int?> _selectedAnswers;

  /// markedForReview[i] = true if the student flagged the question.
  late final List<bool> _markedForReview;

  late int _timeRemaining;
  Timer? _timer;

  // R-8: per-question pacing. secondsSpent[i] is finalized when the user
  // MOVES OFF question i (not while it's still open); the current question
  // spends live from _questionStopwatch. Drives the pace hint chip and
  // the average-time stat on the results screen.
  late final List<int> _secondsSpent;
  final Stopwatch _questionStopwatch = Stopwatch();

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _selectedAnswers = List.filled(widget.questions.length, null);
    _markedForReview = List.filled(widget.questions.length, false);
    _secondsSpent = List.filled(widget.questions.length, 0);
    _timeRemaining = widget.durationSeconds;
    _questionStopwatch.start();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        t.cancel();
        _submit(timeExpired: true);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// R-8: closes the stopwatch for the current question and books the
  /// elapsed time into [_secondsSpent] before leaving it.
  void _finalizeCurrentPace() {
    _questionStopwatch.stop();
    _secondsSpent[_current] = _questionStopwatch.elapsed.inSeconds;
    _questionStopwatch
      ..reset()
      ..start();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.questions.length) return;
    _finalizeCurrentPace();
    setState(() => _current = index);
    Navigator.pop(context); // close the palette drawer if open
  }

  void _prev() {
    if (_current > 0) {
      _finalizeCurrentPace();
      setState(() => _current--);
    }
  }

  void _next() {
    if (_current < widget.questions.length - 1) {
      _finalizeCurrentPace();
      setState(() => _current++);
    }
  }

  void _selectOption(int idx) {
    if (_submitted) return;
    setState(() => _selectedAnswers[_current] = idx);
  }

  void _toggleMark() {
    setState(() => _markedForReview[_current] = !_markedForReview[_current]);
  }

  // ── Submission ─────────────────────────────────────────────────────────────

  void _confirmSubmit() {
    final palette = ColorPaletteController.instance.current;
    final unanswered = _selectedAnswers.where((a) => a == null).length;
    final marked = _markedForReview.where((m) => m).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(Icons.send_rounded, color: palette.primary),
            const SizedBox(width: 10),
            Text(
              'Submit Paper?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              label: 'Answered',
              value: '${_selectedAnswers.where((a) => a != null).length}',
            ),
            const SizedBox(height: 6),
            _SummaryRow(
              icon: Icons.help_outline_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              label: 'Unanswered',
              value: '$unanswered',
            ),
            const SizedBox(height: 6),
            _SummaryRow(
              icon: Icons.flag_rounded,
              color: AppColors.warning,
              label: 'Marked for review',
              value: '$marked',
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Back',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Submit',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit({bool timeExpired = false}) async {
    if (_submitted) return;
    _stopTimer();
    setState(() => _submitted = true);

    // Build a PracticeSession for XP recording (subject = 'Mock Test').
    final session = PracticeSession(
      subject: 'Mock Test',
      totalQuestions: widget.questions.length,
    );

    for (int i = 0; i < widget.questions.length; i++) {
      final sel = _selectedAnswers[i];
      if (sel == null) {
        session.recordTimeout(questionIndex: i);
      } else {
        session.recordAnswer(
          questionIndex: i,
          selectedAnswer: sel,
          correctAnswer: widget.questions[i].correctAnswer,
        );
      }
    }

    int xpEarned = 0;
    try {
      xpEarned = await UserProgressService.instance.recordSession(session);

      // R-3: weak-area tracking batch (a timeout counts as a miss).
      await WeakAreaTrackingService.instance.recordQuestionOutcomes([
        for (var i = 0; i < widget.questions.length; i++)
          if (session.completedQuestions.contains(i))
            (
              question: widget.questions[i],
              isCorrect: session.selectedAnswers[i] ==
                  widget.questions[i].correctAnswer,
            ),
      ]);
    } catch (_) {}

    if (!mounted) return;
    // R-8: book the final question's time for the results average.
    _finalizeCurrentPace();
    // P4-REGRESSION #3: use push so device back works normally.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockTestResultsScreen(
          questions: widget.questions,
          selectedAnswers: _selectedAnswers,
          xpEarned: xpEarned,
          timeExpired: timeExpired,
          secondsSpent: _secondsSpent,
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Which section index does question [i] belong to?
  /// Sections: Physics (0-44), Chemistry (45-89), Biology (90-179)
  String _sectionOf(int i) {
    final q = widget.questions[i];
    return q.subject;
  }

  Color _paletteColor(int i) {
    final palette = ColorPaletteController.instance.current;
    final sel = _selectedAnswers[i];
    final marked = _markedForReview[i];
    if (marked && sel != null) return palette.primary; // answered+marked
    if (marked) return AppColors.warning; // amber
    if (sel != null) return AppColors.success; // answered
    if (i == _current) return palette.primary;
    return Theme.of(context).colorScheme.outline; // not visited
  }

  Color _paletteTextColor(int i) {
    final sel = _selectedAnswers[i];
    final marked = _markedForReview[i];
    if (marked || sel != null || i == _current) return Colors.white;
    return Theme.of(context).colorScheme.onSurface;
  }

  void _openPalette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Question Palette',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _LegendItem(color: Theme.of(context).colorScheme.outline, label: 'Not visited', textColor: Theme.of(context).colorScheme.onSurface),
                  _LegendItem(color: AppColors.success, label: 'Answered'),
                  _LegendItem(color: AppColors.warning, label: 'Marked'),
                  _LegendItem(
                    color: ColorPaletteController.instance.current.primary,
                    label: 'Answered + Marked',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final s in _paletteSections())
                    _buildPaletteSection(s.label, s.start, s.end),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Derive palette sections from the actual question list at runtime.
  /// Each section covers a contiguous run of the same subject. The
  /// repository guarantees physics → chemistry → biology ordering, but
  /// this works for any subject string in case that changes. Previously
  /// hardcoded (0,45,90,length) which crashed on Quick Mock's 45-question
  /// list.
  List<({String label, int start, int end})> _paletteSections() {
    final sections = <({String label, int start, int end})>[];
    if (widget.questions.isEmpty) return sections;
    String current = widget.questions.first.subject;
    int start = 0;
    for (int i = 1; i < widget.questions.length; i++) {
      if (widget.questions[i].subject != current) {
        sections.add((label: current, start: start, end: i));
        current = widget.questions[i].subject;
        start = i;
      }
    }
    sections.add((label: current, start: start, end: widget.questions.length));
    return sections;
  }

  Widget _buildPaletteSection(String label, int start, int end) {
    final count = end - start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: count,
          itemBuilder: (_, idx) {
            final qIdx = start + idx;
            return GestureDetector(
              onTap: () => _goTo(qIdx),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _paletteColor(qIdx),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${qIdx + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _paletteTextColor(qIdx),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final q = widget.questions[_current];
    final section = _sectionOf(_current);
    final selected = _selectedAnswers[_current];
    final isMarked = _markedForReview[_current];

    final isLowTime = _timeRemaining < 600; // < 10 minutes
    final isCritical = _timeRemaining < 120; // < 2 minutes

    // R-8: live pace hint — is THIS question running past its expected
    // time? (Rebuilds every second via the session timer's setState.)
    final livePaceSeconds = _questionStopwatch.elapsed.inSeconds;
    final isRunningSlow = !_submitted &&
        PaceUtils.isSlowAnswer(q, livePaceSeconds);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Text('Exit Exam?',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
            content: Text(
              'Your progress will be lost. Are you sure you want to exit?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Stay',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (exit == true && mounted) {
          _stopTimer();
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        }

      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.06),
          leading: const BackButtonToHome(),
          titleSpacing: 16,
          title: Row(
            children: [
              // Section chip — flexible so a long section name ellipsizes
              // instead of overflowing the app bar on narrow screens.
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _sectionColor(section).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    section,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _sectionColor(section),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Q counter — also flexible so it never overflows next to the
              // timer / palette / submit actions.
              Flexible(
                child: Text(
                  'Q ${_current + 1} / ${widget.questions.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              // R-8: gentle "you're over pace on THIS question" hint.
              if (isRunningSlow) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded,
                          size: 11, color: AppColors.warning),
                      SizedBox(width: 3),
                      Text(
                        'Slow',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // Timer
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isCritical
                    ? AppColors.error.withValues(alpha: 0.1)
                    : isLowTime
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : palette.primarySubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isCritical
                        ? AppColors.error
                        : isLowTime
                            ? AppColors.warning
                            : palette.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isCritical
                          ? AppColors.error
                          : isLowTime
                              ? AppColors.warning
                              : palette.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Palette
            IconButton(
              onPressed: _openPalette,
              icon: const Icon(Icons.grid_view_rounded),
              color: Theme.of(context).colorScheme.onSurface,
              tooltip: 'Question Palette',
            ),
            // Submit
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _confirmSubmit,
                style: TextButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_current + 1) / widget.questions.length,
              minHeight: 3,
              backgroundColor: Theme.of(context).colorScheme.outline,
              valueColor:
                  AlwaysStoppedAnimation<Color>(_sectionColor(section)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question text
                    Text(
                      formatNumericDisplay(
                        q.question.replaceFirst(
                          RegExp(r'^\[See diagram [^\]]+\]\s*'),
                          '',
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),

                    // Diagram (SVG or PNG via shared widget; soft-fails if missing)
                    if (q.diagramId != null) ...[
                      const SizedBox(height: 20),
                      QuestionDiagram(diagramId: q.diagramId),
                    ],

                    const SizedBox(height: 28),

                    // Options
                    ...List.generate(q.options.length, (idx) {
                      final isSelected = selected == idx;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectOption(idx),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primary.withValues(alpha: 0.08)
                                  : Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? palette.primary
                                    : Theme.of(context).colorScheme.outline,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? palette.primary
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    String.fromCharCode(65 + idx),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    formatNumericDisplay(q.options[idx]),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
            ),
            child: Row(
              children: [
                // Mark for review
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleMark,
                    icon: Icon(
                      isMarked ? Icons.flag_rounded : Icons.flag_outlined,
                      size: 18,
                      color: isMarked
                          ? AppColors.warning
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      isMarked ? 'Marked' : 'Mark',
                      style: TextStyle(
                        color: isMarked
                            ? AppColors.warning
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isMarked
                            ? AppColors.warning
                            : Theme.of(context).colorScheme.outline,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Clear selection
                if (selected != null)
                  IconButton(
                    onPressed: () =>
                        setState(() => _selectedAnswers[_current] = null),
                    icon: const Icon(Icons.clear_rounded),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    tooltip: 'Clear selection',
                  ),
                const SizedBox(width: 4),
                // Prev
                IconButton(
                  onPressed: _current > 0 ? _prev : null,
                  icon: Icon(Icons.chevron_left_rounded),
                  color: _current > 0 ? palette.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                  iconSize: 32,
                ),
                // Next / Save & Next
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _current < widget.questions.length - 1
                        ? _next
                        : _confirmSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _current < widget.questions.length - 1
                          ? 'Next →'
                          : 'Submit',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _sectionColor(String subject) {
    switch (subject) {
      case 'Physics':
        return AppColors.physics;
      case 'Chemistry':
        return AppColors.chemistry;
      default:
        return AppColors.biology;
    }
  }
}

// ── Small helper widgets ─────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant))),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;

  const _LegendItem({
    required this.color,
    required this.label,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
