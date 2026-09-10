import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/back_button_to_home.dart';
import '../../models/practice_session.dart';
import '../question/question_screen.dart';
import '../practice_screen.dart';

class ResultsScreen extends StatelessWidget {
  final PracticeSession session;

  /// XP earned from this session as reported by
  /// [UserProgressService.recordSession]. Shown as a reward chip when
  /// > 0 (regular practice previously showed nothing — progress was
  /// never recorded for this flow).
  final int xpEarned;

  /// The setup the session was started with, echoed back into
  /// "Practice Again" so the retry reruns the same configuration
  /// (count / difficulty / time limit) instead of falling back to
  /// the bare 10-question defaults.
  final int questionCount;
  final String difficulty;
  final int? timeLimit;

  const ResultsScreen({
    super.key,
    required this.session,
    this.xpEarned = 0,
    this.questionCount = 10,
    this.difficulty = 'Mixed',
    this.timeLimit = 60,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = session.accuracy.round();
    final palette = ColorPaletteController.instance.current;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: Text(
          "Results",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: palette.primary,
                  size: 44,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                "Practice Complete!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Great work! Here's how you performed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 30),

              if (xpEarned > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: palette.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+$xpEarned XP earned",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      session.subject,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "${session.correctAnswers} / ${session.totalQuestions}",
                      style: TextStyle(
                        color: palette.primary,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Score",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.check_circle_rounded,
                            value: "${session.correctAnswers}",
                            label: "Correct",
                            iconColor: AppColors.success,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.cancel_rounded,
                            value: "${session.incorrectAnswers}",
                            label: "Incorrect",
                            iconColor: AppColors.error,
                          ),
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.percent_rounded,
                            value: "$percentage%",
                            label: "Accuracy",
                            iconColor: palette.primary,
                          ),
                        ),
                      ],
                    ),

                    if (session.unansweredQuestions > 0) ...[
                      const SizedBox(height: 20),
                      _StatItem(
                        icon: Icons.hourglass_empty_rounded,
                        value: "${session.unansweredQuestions}",
                        label: "Unanswered",
                        iconColor: AppColors.warning,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // P4-REGRESSION #3: use push (not pushReplacement) so
                    // device back has a route to pop to.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuestionScreen(
                          subject: session.subject,
                          questionCount: questionCount,
                          difficulty: difficulty,
                          timeLimit: timeLimit,
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
                    "Practice Again",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PracticeScreen(),
                      ),
                          (route) => route.isFirst,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.primary,
                    side: BorderSide(
                      color: palette.primary,
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Back to Practice",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}