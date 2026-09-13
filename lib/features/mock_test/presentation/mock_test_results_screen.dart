import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../features/practice/models/question_model.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../data/score_calibration.dart';
import '../../navigation/main_nav_screen.dart';

/// Results screen displayed after submitting a full-length Mock Test.
///
/// Shows:
/// - Overall NEET score (marking scheme: +4 correct, −1 wrong, 0 skipped).
/// - Section-wise breakdown (Physics / Chemistry / Biology).
/// - Accuracy gauge.
/// - Option to review incorrect answers.
class MockTestResultsScreen extends StatelessWidget {
  final List<QuestionModel> questions;
  final List<int?> selectedAnswers;
  final int xpEarned;
  final bool timeExpired;

  /// R-8: per-question time in seconds (finalized at submission by the
  /// runner). Drives the average-time-per-question stat. Null (legacy
  /// callers/tests) skips that stat.
  final List<int>? secondsSpent;

  const MockTestResultsScreen({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    this.xpEarned = 0,
    this.timeExpired = false,
    this.secondsSpent,
  });

  // ── Score calculations ────────────────────────────────────────────────────

  int get _correct => List.generate(questions.length, (i) {
        final sel = selectedAnswers[i];
        return (sel != null && sel == questions[i].correctAnswer) ? 1 : 0;
      }).fold(0, (a, b) => a + b);

  int get _wrong => List.generate(questions.length, (i) {
        final sel = selectedAnswers[i];
        return (sel != null && sel != questions[i].correctAnswer) ? 1 : 0;
      }).fold(0, (a, b) => a + b);

  int get _skipped => selectedAnswers.where((a) => a == null).length;

  /// NEET marking: +4 per correct, −1 per wrong, 0 for skipped/unattempted.
  int get _neetScore => (_correct * 4) - (_wrong * 1);

  int get _maxScore => questions.length * 4;

  double get _accuracy =>
      questions.isEmpty ? 0 : (_correct / questions.length) * 100;

  /// R-8: average time spent per ATTEMPTED question (answered or
  /// reviewed), in seconds — the honest pace metric. Attempted = every
  /// question that got time booked against it.
  int? get _avgSecondsPerAttempted {
    final spent = secondsSpent;
    if (spent == null || spent.length != questions.length) return null;
    final attempted = <int>[];
    for (var i = 0; i < spent.length; i++) {
      if (selectedAnswers[i] != null && spent[i] > 0) attempted.add(spent[i]);
    }
    if (attempted.isEmpty) return null;
    return attempted.fold<int>(0, (a, b) => a + b) ~/ attempted.length;
  }

  // R-9: calibration from this attempt (null when nothing attempted).
  ScoreCalibration? get _calibration => ScoreCalibration.from(
        correct: _correct,
        wrong: _wrong,
        totalQuestions: questions.length,
      );

  // Section stats
  Map<String, _SectionStats> _sectionStats() {
    final map = <String, _SectionStats>{};
    for (int i = 0; i < questions.length; i++) {
      final s = questions[i].subject;
      map.putIfAbsent(s, () => _SectionStats(subject: s));
      final sel = selectedAnswers[i];
      if (sel == null) {
        map[s]!.skipped++;
      } else if (sel == questions[i].correctAnswer) {
        map[s]!.correct++;
      } else {
        map[s]!.wrong++;
      }
    }
    return map;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final stats = _sectionStats();
    final score = _neetScore;
    final pct = _accuracy;
    final isGood = pct >= 60;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final error = Theme.of(context).colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          'Mock Test Results',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: onSurface),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            if (timeExpired)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_off_rounded,
                        color: error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Time expired — unanswered questions were marked as skipped.',
                        style:
                            TextStyle(fontSize: 13, color: error),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Hero Score Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isGood ? '🎯 Great attempt!' : '📚 Keep practising!',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/ $_maxScore',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'NEET Score  •  ${pct.round()}% Accuracy',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Accuracy bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isGood ? const Color(0xFF4ADE80) : const Color(0xFFFFB800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ScorePill(
                          label: 'Correct',
                          value: '+${_correct * 4}',
                          color: const Color(0xFF4ADE80)),
                      _ScorePill(
                          label: 'Wrong',
                          value: '-$_wrong',
                          color: const Color(0xFFF87171)),
                      _ScorePill(
                          label: 'Skipped',
                          value: '$_skipped',
                          color: Colors.white.withValues(alpha: 0.5)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // XP badge
            if (xpEarned > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        color: Color(0xFFD97706), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      '+$xpEarned XP earned',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Section Breakdown ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'SECTION BREAKDOWN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            for (final subject in ['Physics', 'Chemistry', 'Biology']) ...[
              if (stats.containsKey(subject))
                _SectionCard(stats: stats[subject]!),
              const SizedBox(height: 10),
            ],

            // ── R-9: calibrated NEET prediction (projection, percentile
            // band, predicted AIR with honest uncertainty) ──
            if (_calibration != null) ...[
              const SizedBox(height: 14),
              _CalibrationCard(calibration: _calibration!),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 24),

            // ── Quick Stats ──
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    value: '$_correct',
                    label: 'Correct',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    icon: Icons.cancel_rounded,
                    color: AppColors.error,
                    value: '$_wrong',
                    label: 'Wrong',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    icon: Icons.remove_circle_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    value: '$_skipped',
                    label: 'Skipped',
                  ),
                ),
              ],
            ),

            // R-8: pace stat — only when timing data is available.
            if (_avgSecondsPerAttempted != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Avg $_avgSecondsPerAttempted per attempted question',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // ── Actions ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MainNavScreen(initialTab: 0)),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Home',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MainNavScreen(initialTab: 1)),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Practice More',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.primary,
                  side: BorderSide(color: palette.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section stats model ───────────────────────────────────────────────────────

class _SectionStats {
  final String subject;
  int correct = 0;
  int wrong = 0;
  int skipped = 0;

  _SectionStats({required this.subject});

  int get total => correct + wrong + skipped;
  int get neetScore => (correct * 4) - wrong;
  int get maxScore => total * 4;
  double get accuracy => total == 0 ? 0 : (correct / total) * 100;
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScorePill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final _SectionStats stats;

  const _SectionCard({required this.stats});

  Color get _subjectColor {
    switch (stats.subject) {
      case 'Physics':
        return AppColors.physics;
      case 'Chemistry':
        return AppColors.chemistry;
      default:
        return AppColors.biology;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _subjectColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stats.subject,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _subjectColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${stats.neetScore} / ${stats.maxScore}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.accuracy / 100,
              minHeight: 6,
              backgroundColor: Theme.of(context).colorScheme.outline,
              valueColor: AlwaysStoppedAnimation<Color>(_subjectColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                  label: '✓ ${stats.correct}',
                  color: AppColors.success),
              const SizedBox(width: 12),
              _MiniStat(
                  label: '✗ ${stats.wrong}',
                  color: AppColors.error),
              const SizedBox(width: 12),
              _MiniStat(
                  label: '— ${stats.skipped}',
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const Spacer(),
              Text(
                '${stats.accuracy.round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniStat({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: color),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatBox(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── R-9: calibrated NEET prediction card ─────────────────────────────────

/// Projects this attempt to a full-paper score, maps it through the
/// historical trend to a percentile band and (past the threshold) a
/// predicted AIR — always with the uncertainty note visible so the
/// estimate is never mistaken for a promise.
class _CalibrationCard extends StatelessWidget {
  final ScoreCalibration calibration;

  const _CalibrationCard({required this.calibration});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = calibration;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 18,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              Text(
                'NEET PREDICTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Projected score: ${c.projectedScore} / ${c.maxScore}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current pace held across the questions you left.',
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  'Percentile ~${c.percentileLow.toStringAsFixed(1)}–${c.percentileHigh.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '(mid ${c.percentileMid.toStringAsFixed(1)})',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (c.predictedAir != null) ...[
            const SizedBox(height: 8),
            Text(
              'Predicted AIR ~${c.predictedAirLow}–${c.predictedAirHigh}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${c.confidenceNote} Historical trend estimate — not a guarantee.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
