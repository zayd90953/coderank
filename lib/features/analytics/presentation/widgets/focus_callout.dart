import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_progress_service.dart'
    show SessionRecord, SubjectStat;
import '../../../../features/practice/presentation/setup/practice_setup_screen.dart';
import '../../data/analytics_aggregations.dart';

/// A-5: the "Focus this week" callout that points the user at the
/// subject with the lowest accuracy (subject-level only — per-chapter
/// is R-3 scope).
///
/// The accuracy shown is computed **over the last 7 days** from session
/// history, so the number matches the "this week" label. Subjects with
/// too few questions in the window (below [minQuestions]) are excluded —
/// no "Chemistry is your weakest!" verdict on the basis of 2 questions.
///
/// Hidden entirely when no subject has enough weekly data. In that case
/// we fall back to the **all-time** weakest subject when it has enough
/// overall volume ([minAllTimeQuestions]) — so new-ish users still see a
/// useful pointer instead of a blank spot — otherwise the callout is
/// simply not shown.
class FocusCallout extends StatelessWidget {
  final Map<String, SubjectStat> subjectStats;

  /// Session history used to compute genuine weekly accuracy per subject.
  final List<SessionRecord> history;

  /// Minimum questions a subject needs **this week** before its weekly
  /// accuracy is trusted.
  final int minQuestions;

  /// Minimum all-time questions before the all-time fallback kicks in
  /// (when no subject has weekly data).
  final int minAllTimeQuestions;

  const FocusCallout({
    super.key,
    required this.subjectStats,
    required this.history,
    this.minQuestions = 5,
    this.minAllTimeQuestions = 20,
  });

  /// Resolves the subject to show, or `null` to hide the callout.
  ///
  /// 1. Prefer the subject with the lowest **weekly** accuracy among
  ///    subjects with ≥ [minQuestions] questions in the last 7 days.
  /// 2. If no subject has weekly data, fall back to the all-time
  ///    weakest subject (≥ [minAllTimeQuestions] questions) so the
  ///    card still helps users who don't practice three subjects a week.
  ({String subject, double accuracy, int questions, bool isWeekly})?
      _resolveFocus() {
    // 1) Weekly scan.
    String? weeklyWeakest;
    var weeklyAcc = 101.0;
    var weeklyQs = 0;
    for (final subject in subjectStats.keys) {
      final w = AnalyticsAggregations.weeklyAccuracyForSubject(
        history,
        subject,
        minQuestions: minQuestions,
      );
      if (w == null) continue;
      if (w.accuracy < weeklyAcc ||
          (w.accuracy == weeklyAcc && w.questions > weeklyQs)) {
        weeklyAcc = w.accuracy;
        weeklyQs = w.questions;
        weeklyWeakest = subject;
      }
    }
    if (weeklyWeakest != null) {
      return (
        subject: weeklyWeakest,
        accuracy: weeklyAcc,
        questions: weeklyQs,
        isWeekly: true,
      );
    }

    // 2) All-time fallback.
    final allTime = AnalyticsAggregations.weakestSubject(
      subjectStats,
      minQuestions: minAllTimeQuestions,
    );
    if (allTime != null) {
      final stat = subjectStats[allTime]!;
      return (
        subject: allTime,
        accuracy: stat.accuracy,
        questions: stat.totalQuestions,
        isWeekly: false,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final focus = _resolveFocus();
    if (focus == null) return const SizedBox.shrink();

    final weakest = focus.subject;
    final acc = focus.accuracy.round();
    final tint = _tintFor(weakest);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
              color: AppColors.textOnPrimary,
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
                    Text(
                      'Focus this week',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  focus.isWeekly
                      ? '$acc% accuracy across ${focus.questions} questions this week'
                      : '$acc% accuracy across ${focus.questions} questions (all time)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  focus.isWeekly
                      ? 'Your lowest-scoring subject this week — one focused practice will move the needle.'
                      : 'Not enough practice this week for a weekly score — here\'s your all-time weakest subject.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            Icon(
                              Icons.bolt_rounded,
                              color: AppColors.textOnPrimary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Practice $weakest',
                              style: TextStyle(
                                color: AppColors.textOnPrimary,
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

  // The "Practice X" button always sits on a colored tint, so the label
  // uses the dark-on-brand color regardless of the app theme.
}
