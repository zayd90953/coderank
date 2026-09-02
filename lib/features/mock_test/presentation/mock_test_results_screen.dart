import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../features/practice/models/question_model.dart';
import '../../../shared/widgets/back_button_to_home.dart';
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

  const MockTestResultsScreen({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    this.xpEarned = 0,
    this.timeExpired = false,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: const Text(
          'Mock Test Results',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text),
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
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_off_rounded,
                        color: AppColors.error, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Time expired — unanswered questions were marked as skipped.',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.error),
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
                  color: const Color(0xFFFFF7ED),
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
                  color: AppColors.subtitle,
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
                    color: AppColors.subtitle,
                    value: '$_skipped',
                    label: 'Skipped',
                  ),
                ),
              ],
            ),

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8F5)),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
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
              backgroundColor: const Color(0xFFF0ECF8),
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
                  color: AppColors.subtitle),
              const Spacer(),
              Text(
                '${stats.accuracy.round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.subtitle,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8F5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.subtitle)),
        ],
      ),
    );
  }
}
