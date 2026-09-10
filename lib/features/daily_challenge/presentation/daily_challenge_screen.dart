import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/theme/color_palette.dart';
import '../../../shared/services/user_progress_service.dart';
import '../../../shared/widgets/back_button_to_home.dart';
import '../../practice/data/question_repository.dart';
import '../../practice/models/question_model.dart';
import 'daily_challenge_question_screen.dart';


/// A-3: launcher for the Daily NEET Challenge.
///
/// Shows the existing banner + details layout. The bottom button
/// behaviour depends on whether the user has already completed today's
/// daily:
///   * Completed today  → disabled, labelled "✅ Completed — come back tomorrow"
///   * Otherwise       → fetches 10 questions via
///     [QuestionRepository.getDailyChallengeQuestions] and pushes
///     [DailyChallengeQuestionScreen].
///
/// When the user returns from the question screen, [UserProgressService]
/// may have stamped the "completed today" flag, so this screen
/// automatically reflects the new state via the
/// [ValueListenableBuilder] on `progressNotifier`.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _startDailyChallenge() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final questions =
          await QuestionRepository().getDailyChallengeQuestions();

      if (!mounted) return;

      if (questions.isEmpty) {
        setState(() {
          _isLoading = false;
          _error =
              "No daily challenge questions available right now. Please try again later.";
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // P4-REGRESSION #3: use push (not pushReplacement) so the device
      // back gesture pops to the launcher instead of exiting the app.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DailyChallengeQuestionScreen(questions: questions),
        ),
      );
      // When we return, the question screen may have stamped
      // `lastDailyChallengeDate`. The `ValueListenableBuilder` on
      // `progressNotifier` will rebuild this screen, so the button
      // automatically flips to its "Completed" state.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            "Failed to load Daily Challenge questions. Please try again.";
      });
    }
  }

  String _formatLastDate(String yyyymmdd) {
    // Best-effort formatting for "Last completed: 5 Sep 2026".
    if (yyyymmdd.isEmpty) return '';
    final parts = yyyymmdd.split('-');
    if (parts.length != 3) return yyyymmdd;
    final monthNum = int.tryParse(parts[1]) ?? 0;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (monthNum < 1 || monthNum > 12) return yyyymmdd;
    return '${parts[2]} ${months[monthNum - 1]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    return ValueListenableBuilder<UserProgressData>(
      valueListenable: UserProgressService.instance.progressNotifier,
      builder: (context, data, _) {
        final completedToday = UserProgressService
            .instance.dailyChallengeCompletedToday();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButtonToHome(),
            title: Text(
              "Daily NEET Challenge",
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
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.textOnPrimary,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "${data.streakDays} Day Streak!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Complete today's 10 high-yield NTA NEET questions to keep your streak alive & earn XP!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textOnPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Daily Rules ──
                Text(
                  "CHALLENGE DETAILS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),

                _DetailRow(
                  icon: Icons.quiz_rounded,
                  color: palette.primary,
                  title: "10 High-Yield Questions",
                  subtitle:
                      "4 Biology + 3 Physics + 3 Chemistry — same set for every user today",
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.timer_rounded,
                  color: AppColors.warning,
                  title: "45s Speed Timer",
                  subtitle: "Test speed & rapid recall under pressure",
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.bolt_rounded,
                  color: AppColors.success,
                  title: "Daily Completion Bonus",
                  subtitle:
                      "Earn +50 XP on top of regular session rewards when you finish all 10",
                ),

                const SizedBox(height: 36),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),

                if (completedToday) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            palette.primary.withValues(alpha: 0.4),
                        disabledBackgroundColor:
                            palette.primary.withValues(alpha: 0.4),
                        foregroundColor: AppColors.textOnPrimary,
                        disabledForegroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "✅ Completed — come back tomorrow",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (data.lastDailyChallengeDate.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "Last completed: ${_formatLastDate(data.lastDailyChallengeDate)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ] else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startDailyChallenge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.textOnPrimary,
                              ),
                            )
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
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

// Suppress unused-import warning for the type annotation on
// [QuestionModel] — kept for future signature use and clarity.
// ignore: unused_element
typedef _UnusedQuestionModelRef = QuestionModel;
