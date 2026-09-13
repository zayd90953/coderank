import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../practice/models/practice_session.dart';
import '../../practice/models/question_model.dart';

/// R-4: diagnostic results — the "chapter map".
///
/// Groups the just-finished diagnostic's per-chapter outcomes into three
/// bands and renders them as a sortable visual map:
///   * Strong   (>= 80% accuracy, >= 2 attempts)
///   * Shaky    (everything in between)
///   * Unproven (0 attempts — chapter wasn't sampled this round)
///
/// The map itself is a snapshot of THIS run; the persistent cross-session
/// weak-area view lives in Analytics (R-5/R-6 consumers).
class DiagnosticResultsScreen extends StatelessWidget {
  final String subject;
  final PracticeSession session;
  final List<QuestionModel> questions;
  final int bonusXp;

  const DiagnosticResultsScreen({
    super.key,
    required this.subject,
    required this.session,
    required this.questions,
    required this.bonusXp,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = ColorPaletteController.instance.current;

    // Per-chapter outcomes from THIS run.
    final attempts = <String, int>{};
    final correct = <String, int>{};
    for (var i = 0; i < questions.length; i++) {
      if (!session.completedQuestions.contains(i)) continue;
      final chapter = questions[i].chapter;
      attempts[chapter] = (attempts[chapter] ?? 0) + 1;
      if (session.selectedAnswers[i] == questions[i].correctAnswer) {
        correct[chapter] = (correct[chapter] ?? 0) + 1;
      }
    }

    final allChapters = questions.map((q) => q.chapter).toSet().toList()..sort();
    final strong = <String>[];
    final shaky = <String>[];
    final unproven = <String>[];
    for (final chapter in allChapters) {
      final a = attempts[chapter] ?? 0;
      if (a == 0) {
        unproven.add(chapter);
        continue;
      }
      final accuracy = (correct[chapter] ?? 0) / a;
      if (accuracy >= 0.8) {
        strong.add(chapter);
      } else {
        shaky.add(chapter);
      }
    }

    final answered = session.completedQuestions.length;
    final overall = answered > 0
        ? (session.correctAnswers / answered * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          'Your $subject map',
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Headline ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: palette.heroCardGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHECK-UP COMPLETE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$overall% overall',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+$bonusXp XP · $answered chapters sampled',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (shaky.isNotEmpty) ...[
              _Band(
                label: 'Needs work',
                icon: Icons.build_circle_rounded,
                color: AppColors.warning,
                chapters: shaky,
                scheme: scheme,
              ),
              const SizedBox(height: 18),
            ],
            if (strong.isNotEmpty) ...[
              _Band(
                label: 'Strong',
                icon: Icons.verified_rounded,
                color: AppColors.success,
                chapters: strong,
                scheme: scheme,
              ),
              const SizedBox(height: 18),
            ],
            if (unproven.isNotEmpty) ...[
              _Band(
                label: 'Not sampled this round',
                icon: Icons.explore_rounded,
                color: scheme.onSurfaceVariant,
                chapters: unproven,
                scheme: scheme,
              ),
              const SizedBox(height: 18),
            ],

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 18, color: palette.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your practice recommendations now focus on the chapters that need work.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final List<String> chapters;
  final ColorScheme scheme;

  const _Band({
    required this.label,
    required this.icon,
    required this.color,
    required this.chapters,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              '$label (${chapters.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chapter in chapters)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  chapter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
