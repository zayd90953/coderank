import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../daily_challenge/presentation/daily_challenge_screen.dart';
import '../../mock_test/presentation/mock_test_chooser_screen.dart';
import 'setup/practice_setup_screen.dart';

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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Practice Hub hero
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
                                  "$totalQuestions Q solved",
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
                                  "$overallAccuracy%",
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _PracticeStatItem(
                              value: "$streakDays",
                              label: "Day Streak",
                              icon: Icons.local_fire_department_rounded,
                              color: Color(0xFFFF8C00),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            _PracticeStatItem(
                              value: "$totalQuestions",
                              label: "Total Qs",
                              icon: Icons.quiz_rounded,
                              color: AppColors.textOnPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Subject mastery cards
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

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SubjectMasteryCard(
                      subject: "Physics",
                      icon: Icons.bolt_rounded,
                      gradient: AppColors.physicsGradient,
                      stat: subjectStats['Physics'] ??
                          const SubjectStat(subject: 'Physics'),
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
                    _SubjectMasteryCard(
                      subject: "Chemistry",
                      icon: Icons.science_rounded,
                      gradient: AppColors.chemistryGradient,
                      stat: subjectStats['Chemistry'] ??
                          const SubjectStat(subject: 'Chemistry'),
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
                    _SubjectMasteryCard(
                      subject: "Biology",
                      icon: Icons.biotech_rounded,
                      gradient: AppColors.biologyGradient,
                      stat: subjectStats['Biology'] ??
                          const SubjectStat(subject: 'Biology'),
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
                  ],
                ),
                const SizedBox(height: 30),

                // Quick actions
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
                  "One‑tap into your favorite flows.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        label: "Daily Challenge",
                        subtitle: "10 Q • 45s/question • +50 XP",
                        icon: Icons.calendar_today,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DailyChallengeScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        label: "Mock Test",
                        subtitle: "45 Q • 2hr • Orange hero",
                        icon: Icons.quiz,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MockTestChooserScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Optional shortcut to home practice (legacy)
                Text(
                  "Or jump to classic practice",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PracticeSetupScreen(
                            subject: "Physics", // default fallback
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Classic Practice",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubjectMasteryCard extends StatelessWidget {
  final String subject;
  final IconData icon;

  const _SubjectMasteryCard({
    required this.subject,
    required this.icon,
    required this.gradient,
    required this.stat,
    required this.onPracticeTap,
  });

  final LinearGradient gradient;
  final SubjectStat stat;
  final VoidCallback onPracticeTap;

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
                  foregroundColor: palette.primary,
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
            children: [
              Text(
                "Accuracy: $acc%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
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

class _PracticeStatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _PracticeStatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final surfaceContainer = Theme.of(context).colorScheme.surfaceContainer;
    final outline = Theme.of(context).colorScheme.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: outline),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: palette.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}