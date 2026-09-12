import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../../shared/widgets/subject_icon_badge.dart';
import '../../daily_challenge/presentation/daily_challenge_screen.dart';
import '../../mock_test/presentation/mock_test_chooser_screen.dart';
import 'setup/practice_setup_screen.dart';

/// A-6: Practice Hub — the game-like launchpad for all practice flows.
///
/// Structure (per the A-6 item in CODERANK.md — visual/interaction
/// upgrade, functionality preserved):
///   * Gradient hero — "questions solved" headline, accuracy pill, and
///     a streak + XP stat strip. Streak now means "consecutive days
///     with a completed session" (AUD-2), so it earns hero placement.
///   * "Pick your lane" — subject mastery cards (Physics / Chemistry /
///     Biology), each FULLY tappable into [PracticeSetupScreen].
///   * "Quick launch" — Daily Challenge (with a live done-today state)
///     and Mock Test chooser.
///
/// Every color that sits on the fixed hero gradient is mode-independent
/// (white / on-brand dark); everything on theme surfaces reads the
/// active light/dark scheme.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;

    return ValueListenableBuilder<UserProgressData>(
      valueListenable: UserProgressService.instance.progressNotifier,
      builder: (context, data, _) {
        final totalQuestions = data.totalQuestions;
        final streakDays = data.streakDays;
        final subjectStats = data.subjectStats;
        final overallAccuracy = data.overallAccuracy.round();

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButtonToHome(),
            title: Text(
              "Practice Hub",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PracticeHero(
                  palette: palette,
                  totalQuestions: totalQuestions,
                  streakDays: streakDays,
                  overallAccuracy: overallAccuracy,
                  xpPoints: data.xpPoints,
                ),
                const SizedBox(height: 28),

                // ── Subject mastery cards ───────────────────────────
                Text(
                  "Pick your lane",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Start a focused session or review your accuracy.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                _SubjectMasteryCard(
                  subject: "Physics",
                  gradient: AppColors.physicsGradient,
                  stat: subjectStats['Physics'] ??
                      const SubjectStat(subject: 'Physics'),
                  onPracticeTap: () => _openSubject(context, "Physics"),
                ),
                const SizedBox(height: 14),
                _SubjectMasteryCard(
                  subject: "Chemistry",
                  gradient: AppColors.chemistryGradient,
                  stat: subjectStats['Chemistry'] ??
                      const SubjectStat(subject: 'Chemistry'),
                  onPracticeTap: () => _openSubject(context, "Chemistry"),
                ),
                const SizedBox(height: 14),
                _SubjectMasteryCard(
                  subject: "Biology",
                  gradient: AppColors.biologyGradient,
                  stat: subjectStats['Biology'] ??
                      const SubjectStat(subject: 'Biology'),
                  onPracticeTap: () => _openSubject(context, "Biology"),
                ),
                const SizedBox(height: 28),

                // ── Quick actions ───────────────────────────────────
                Text(
                  "Quick launch",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "One tap into your favorite flows.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                _QuickActionCard(
                  label: "Daily Challenge",
                  subtitle: data.lastDailyChallengeDate == _todayKey()
                      ? "Done today — new set unlocks at midnight"
                      : "10 questions · beat the clock · +50 XP",
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF8C00),
                  isDone: data.lastDailyChallengeDate == _todayKey(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyChallengeScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _QuickActionCard(
                  label: "Mock Test",
                  subtitle: "Full-length exam or quick 45Q warm-up",
                  icon: Icons.timer_rounded,
                  iconColor: AppColors.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MockTestChooserScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSubject(BuildContext context, String subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSetupScreen(subject: subject),
      ),
    );
  }

  static String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero
// ─────────────────────────────────────────────────────────────────────────────

class _PracticeHero extends StatelessWidget {
  final ColorPalette palette;
  final int totalQuestions;
  final int streakDays;
  final int overallAccuracy;
  final int xpPoints;

  const _PracticeHero({
    required this.palette,
    required this.totalQuestions,
    required this.streakDays,
    required this.overallAccuracy,
    required this.xpPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: palette.heroCardGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "YOUR PROGRESS",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalQuestions == 0
                          ? "Start your streak"
                          : "$totalQuestions Q solved",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD166),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$overallAccuracy%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroStat(
                    icon: Icons.local_fire_department_rounded,
                    value: "$streakDays",
                    label: streakDays == 1 ? "Day Streak" : "Day Streaks",
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _HeroStat(
                    icon: Icons.bolt_rounded,
                    value: "$xpPoints",
                    label: "Total XP",
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _HeroStat(
                    icon: Icons.quiz_rounded,
                    value: "$totalQuestions",
                    label: "Solved",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subject mastery card — fully tappable
// ─────────────────────────────────────────────────────────────────────────────

class _SubjectMasteryCard extends StatelessWidget {
  final String subject;
  final LinearGradient gradient;
  final SubjectStat stat;
  final VoidCallback onPracticeTap;

  const _SubjectMasteryCard({
    required this.subject,
    required this.gradient,
    required this.stat,
    required this.onPracticeTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final acc = stat.accuracy.round();
    final progress = (acc / 100).clamp(0.0, 1.0);
    final practiced = stat.totalQuestions > 0;

    return InkWell(
      onTap: onPracticeTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SubjectIconBadge(subject: subject, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        practiced
                            ? "${stat.totalQuestions} solved · ${stat.sessionsCount} sessions"
                            : "Not started yet — tap to begin",
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          progress == 0 && practiced ? 0.05 : progress,
                      minHeight: 8,
                      backgroundColor: scheme.outline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        gradient.colors.first,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "$acc%",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick action card
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isDone;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.isDone = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = ColorPaletteController.instance.current;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDone ? palette.primary : scheme.outline,
            width: isDone ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (isDone) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "DONE ✓",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: palette.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
