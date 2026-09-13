import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../practice/presentation/setup/practice_setup_screen.dart';
import '../data/analytics_aggregations.dart';
import 'widgets/focus_callout.dart';
import 'widgets/weekly_trend_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    return ValueListenableBuilder<UserProgressData>(
      valueListenable: UserProgressService.instance.progressNotifier,
      builder: (context, data, _) {
        final totalQuestions = data.totalQuestions;
        final accuracy = data.overallAccuracy.round();
        final streak = data.streakDays;
        final xp = data.xpPoints;
        final tier = data.tier;
        final percentile = data.percentile;
        final predictedAir = data.predictedAir;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Always show a back button — pops if pushed, switches to Home
            // when this screen is the active tab.
            leading: const BackButtonToHome(),
            title: Text(
              "Performance Analytics",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Overview Card
                Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "NEET PREDICTION",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                predictedAir,
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFFD166),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  percentile,
                                  style: TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _HeroStatItem(
                              value: "$totalQuestions",
                              label: "Solved",
                              icon: Icons.quiz_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            _HeroStatItem(
                              value: "$accuracy%",
                              label: "Accuracy",
                              icon: Icons.track_changes_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            _HeroStatItem(
                              value: "$xp XP",
                              label: tier,
                              icon: Icons.bolt_rounded,
                            ),
                          ],
                        ),
                      ),
                      // B-5: while the ranking gate is active, tell the user
                      // exactly what unlocks the NEET prediction.
                      if (!data.isRankingUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Answer ${data.rankingQuestionsRemaining} more questions to unlock your NEET prediction",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF8C00),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "$streak Day Study Streak • Practice today to keep it active!",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // A-5: weekly trend (accuracy bar chart + streak dots).
                WeeklyTrendCard(history: data.history),
                const SizedBox(height: 16),

                // A-5: focus this week weak-area callout. Now computes
                // genuine weekly accuracy per subject from session history,
                // with an all-time fallback when weekly data is thin.
                FocusCallout(
                  subjectStats: data.subjectStats,
                  history: data.history,
                ),
                const SizedBox(height: 30),

                // Subject Mastery Breakdown
                Text(
                  "Subject Mastery",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Track your accuracy and solved questions across NEET subjects.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                _SubjectMasteryCard(
                  subject: "Physics",
                  icon: Icons.bolt_rounded,
                  gradient: AppColors.physicsGradient,
                  stat: data.subjectStats['Physics'] ??
                      const SubjectStat(subject: 'Physics'),
                  direction: AnalyticsAggregations.trendWindowForSubject(
                          data.history, 'Physics')
                      .direction(),
                  onPracticeTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PracticeSetupScreen(subject: "Physics"),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _SubjectMasteryCard(
                  subject: "Chemistry",
                  icon: Icons.science_rounded,
                  gradient: AppColors.chemistryGradient,
                  stat: data.subjectStats['Chemistry'] ??
                      const SubjectStat(subject: 'Chemistry'),
                  direction: AnalyticsAggregations.trendWindowForSubject(
                          data.history, 'Chemistry')
                      .direction(),
                  onPracticeTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PracticeSetupScreen(subject: "Chemistry"),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _SubjectMasteryCard(
                  subject: "Biology",
                  icon: Icons.biotech_rounded,
                  gradient: AppColors.biologyGradient,
                  stat: data.subjectStats['Biology'] ??
                      const SubjectStat(subject: 'Biology'),
                  direction: AnalyticsAggregations.trendWindowForSubject(
                          data.history, 'Biology')
                      .direction(),
                  onPracticeTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PracticeSetupScreen(subject: "Biology"),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // AI Insights & Recommendations
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.primarySubtle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.psychology_rounded,
                              color: palette.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              "AI Study Insights",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _InsightRow(
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        title: accuracy >= 75
                            ? "High Accuracy Benchmark"
                            : "Building Foundation",
                        description: accuracy >= 75
                            ? "Your accuracy ($accuracy%) is competitive for top medical colleges. Maintain this with mixed difficulty mock tests."
                            : "Aim for 80%+ accuracy by focusing on conceptual questions in Biology and Physical Chemistry.",
                      ),
                      const SizedBox(height: 10),
                      _InsightRow(
                        icon: Icons.speed_rounded,
                        color: AppColors.physics,
                        title: "Daily Goal: 20 Questions",
                        description: totalQuestions < 20
                            ? "Solve at least 20 questions daily to climb the leaderboard to Diamond Tier."
                            : "Great consistency! You've solved $totalQuestions questions so far.",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Recent Sessions History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Practice History",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (data.history.isNotEmpty)
                      Text(
                        "${data.history.length} Sessions",
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                if (data.history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No Practice Sessions Yet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Complete a practice test to see your history and stats.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...data.history.take(10).map((record) {
                    final acc = record.accuracy.round();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _getSubjectColor(record.subject)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getSubjectIcon(record.subject),
                              color: _getSubjectColor(record.subject),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.subject,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  "${record.correct} of ${record.total} correct • +${record.xpGained} XP",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: acc >= 75
                                  ? AppColors.success.withValues(alpha: 0.12)
                                  : AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$acc%",
                              style: TextStyle(
                                color: acc >= 75
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSubjectColor(String subject) {
    if (subject.toLowerCase().contains("phys")) return AppColors.physics;
    if (subject.toLowerCase().contains("chem")) return AppColors.chemistry;
    return AppColors.biology;
  }

  IconData _getSubjectIcon(String subject) {
    if (subject.toLowerCase().contains("phys")) return Icons.bolt_rounded;
    if (subject.toLowerCase().contains("chem")) return Icons.science_rounded;
    return Icons.biotech_rounded;
  }
}

class _HeroStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeroStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SubjectMasteryCard extends StatelessWidget {
  final String subject;
  final IconData icon;
  final LinearGradient gradient;
  final SubjectStat stat;

  /// A-5: optional trend indicator (up/down/steady) for this subject.
  final TrendDirection? direction;

  final VoidCallback onPracticeTap;

  const _SubjectMasteryCard({
    required this.subject,
    required this.icon,
    required this.gradient,
    required this.stat,
    required this.onPracticeTap,
    this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final acc = stat.accuracy.round();
    final progress = (acc / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.textOnPrimary, size: 24),
              ),
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${stat.totalQuestions} questions solved • ${stat.sessionsCount} sessions",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onPracticeTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: palette.primarySubtle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Practice",
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Accuracy: $acc%",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (direction != null) ...[
                    const SizedBox(width: 8),
                    _TrendPill(direction: direction!),
                  ],
                ],
              ),
              Text(
                stat.totalQuestions == 0 ? "Not started" : "${stat.correctAnswers}/${stat.totalQuestions} correct",
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress == 0 && stat.totalQuestions > 0 ? 0.05 : progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.outline,
              valueColor: AlwaysStoppedAnimation<Color>(
                gradient.colors.first,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  final TrendDirection direction;
  const _TrendPill({required this.direction});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;
    Color bg;
    Color fg;
    switch (direction) {
      case TrendDirection.up:
        icon = Icons.trending_up_rounded;
        label = 'trending';
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        break;
      case TrendDirection.down:
        icon = Icons.trending_down_rounded;
        label = 'dropping';
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
      case TrendDirection.steady:
        icon = Icons.trending_flat_rounded;
        label = 'steady';
        bg = Theme.of(context).colorScheme.surfaceContainerHighest;
        fg = Theme.of(context).colorScheme.onSurfaceVariant;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 11),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _InsightRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
