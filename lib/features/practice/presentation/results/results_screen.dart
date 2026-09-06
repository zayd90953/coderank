import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/widgets/back_button_to_home.dart';
import '../../models/practice_session.dart';
import '../question/question_screen.dart';
import '../practice_screen.dart';

class ResultsScreen extends StatelessWidget {
  final PracticeSession session;

  const ResultsScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = session.accuracy.round();
    final palette = ColorPaletteController.instance.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButtonToHome(),
        title: const Text(
          "Results",
          style: TextStyle(
            color: AppColors.textPrimary,
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

              const Text(
                "Practice Complete!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Great work! Here's how you performed.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      session.subject,
                      style: TextStyle(
                        color: AppColors.textSecondary,
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

                    const Text(
                      "Score",
                      style: TextStyle(
                        color: AppColors.textPrimary,
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
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}