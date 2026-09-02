import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../practice/presentation/question/question_screen.dart';


/// Real implementation of Daily NEET Challenge flow.
///
/// Features:
/// - Daily streak tracking integration.
/// - Selected high-yield NEET PYQs (10 questions daily challenge).
/// - XP multipliers for maintaining study streak.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _startDailyChallenge() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const QuestionScreen(
            subject: "Daily Challenge",
            questionCount: 10,
            difficulty: "Mixed",
            timeLimit: 45, // 45 seconds per high-yield question
          ),
        ),
      );
    } catch (e) {

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Failed to load Daily Challenge questions. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    return ValueListenableBuilder<UserProgressData>(
      valueListenable: UserProgressService.instance.progressNotifier,
      builder: (context, data, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F7FD),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.text,
            ),
            title: const Text(
              "Daily NEET Challenge",
              style: TextStyle(
                color: AppColors.text,
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
                // ── Challenge Banner ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.fireStreakGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4500).withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "${data.streakDays} Day Streak!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Complete today's 10 high-yield NTA NEET questions to keep your streak alive & earn 2x XP!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Daily Rules ──
                const Text(
                  "CHALLENGE DETAILS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.subtitle,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),

                _DetailRow(
                  icon: Icons.quiz_rounded,
                  color: palette.primary,
                  title: "10 High-Yield Questions",
                  subtitle: "Handpicked NTA PYQs across Physics, Chem & Bio",
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.timer_rounded,
                  color: const Color(0xFFD97706),
                  title: "45s Speed Timer",
                  subtitle: "Test speed & rapid recall under pressure",
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.bolt_rounded,
                  color: AppColors.success,
                  title: "Double XP Bonus",
                  subtitle: "Earn +30 bonus XP on top of regular session rewards",
                ),

                const SizedBox(height: 36),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startDailyChallenge,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "🔥 Start Today's Challenge",
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
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _DetailRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8F5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitle,
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
