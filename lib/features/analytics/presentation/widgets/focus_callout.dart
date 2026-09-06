import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_progress_service.dart' show SubjectStat;
import '../../../../features/practice/presentation/setup/practice_setup_screen.dart';
import '../../data/analytics_aggregations.dart';

/// A-5: the "Focus this week" callout that points the user at the
/// subject with the lowest accuracy (subject-level only — per-chapter
/// is R-3 scope).
///
/// Hidden entirely if no subject has at least [minQuestions] questions
/// solved — we don't want to call "Chemistry is your weakest!" on the
/// basis of 3 questions.
class FocusCallout extends StatelessWidget {
  final Map<String, SubjectStat> subjectStats;

  /// Matches [AnalyticsAggregations.weakestSubject] default.
  final int minQuestions;

  const FocusCallout({
    super.key,
    required this.subjectStats,
    this.minQuestions = 20,
  });

  @override
  Widget build(BuildContext context) {
    final weakest = AnalyticsAggregations.weakestSubject(
      subjectStats,
      minQuestions: minQuestions,
    );
    if (weakest == null) return const SizedBox.shrink();

    final stat = subjectStats[weakest]!;
    final acc = stat.accuracy.round();
    final tint = _tintFor(weakest);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tint.withValues(alpha: 0.85), tint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.priority_high_rounded,
              color: AppColors.surface,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Focus this week',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        weakest.toUpperCase(),
                        style: TextStyle(
                          color: tint,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$acc% accuracy across ${stat.totalQuestions} questions',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your lowest-scoring subject — one focused practice will move the needle.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _openPractice(context, weakest),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: AppColors.surface,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Practice $weakest',
                              style: TextStyle(
                                color: _contrastOn(tint),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPractice(BuildContext context, String subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeSetupScreen(subject: subject),
      ),
    );
  }

  Color _tintFor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('phys')) return AppColors.physics;
    if (s.contains('chem')) return AppColors.chemistry;
    if (s.contains('bio')) return AppColors.biology;
    return ColorPaletteController.instance.current.primary;
  }

  // Subject tints (Physics/Chemistry/Biology) are bright on a dark
  // surface, so white text reads well on the "Practice X" button.
  // The brand primary, however, can vary by palette (forest green,
  // ocean blue, electric green, purple) — for those we still want
  // AppColors.surface (#0D0D0D) for AA contrast.
  Color _contrastOn(Color background) {
    // Quick luminance check.
    final luminance = background.computeLuminance();
    return luminance > 0.55 ? AppColors.textOnPrimary : AppColors.surface;
  }
}
