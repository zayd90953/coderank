import '../../../shared/services/user_progress_service.dart';
import '../../../shared/services/weak_area_tracking_service.dart';

/// R-5: what should this student do next?
///
/// A pure priority engine: [RecommendationEngine.build] takes the current
/// state (progress, weak areas, daily/diagnostic flags) and returns at
/// most [maxRecommendations] actionable recommendations, most urgent
/// first. It contains NO Flutter and NO singletons — the UI (R-6 home
/// rework) renders the results and owns routing; a thin
/// [RecommendationEngine.buildForCurrentUser] convenience pulls the live
/// services for callers that just want the list.
///
/// Honesty thresholds (mirroring the FocusCallout philosophy — never
/// diagnose from two data points):
///   * A weak-chapter drill needs >= [minAttemptsForWeakness] attempts in
///     that chapter and accuracy <= [weaknessAccuracyThreshold].
///   * The diagnostic nudge only fires once the user has practiced
///     enough (>= [minQuestionsBeforeDiagnostic]) for a check-up to mean
///     something.
///   * A mistake-review needs >= [minMistakesForReview] unresolved misses.
/// If nothing qualifies, a momentum fallback keeps the card non-empty.
enum RecommendationKind {
  /// Practice now to keep the streak alive (streak > 0, nothing today).
  streakKeeper,

  /// Today's Daily Challenge is still unclaimed.
  dailyChallenge,

  /// No recent diagnostic (or stale) — map your strengths.
  diagnosticNudge,

  /// A chapter with enough attempts and low accuracy — drill it.
  weakChapterDrill,

  /// A pile of unresolved recent mistakes — revisit them.
  mistakeReview,

  /// Fallback: keep practicing (least-practiced subject).
  momentum,
}

class StudyRecommendation {
  final RecommendationKind kind;

  /// Short imperative headline, e.g. "Save your 5-day streak".
  final String title;

  /// One line of why + what happens on tap.
  final String subtitle;

  /// Routing payload (nullable depending on kind).
  final String? subject;
  final String? chapter;

  const StudyRecommendation({
    required this.kind,
    required this.title,
    required this.subtitle,
    this.subject,
    this.chapter,
  });
}

class RecommendationEngine {
  RecommendationEngine._();

  /// Hard cap on returned recommendations — the home card shows 3.
  static const int maxRecommendations = 3;

  // ── Honesty thresholds ──
  static const int minAttemptsForWeakness = 4;
  static const double weaknessAccuracyThreshold = 60.0;
  static const int minQuestionsBeforeDiagnostic = 20;
  static const int minMistakesForReview = 5;

  /// A diagnostic older than this (or never taken) counts as stale.
  static const int diagnosticRefreshDays = 14;

  /// Builds the prioritized recommendation list.
  static List<StudyRecommendation> build({
    required UserProgressData progress,
    required WeakAreaData weakAreas,
    required bool dailyChallengeDoneToday,
    DateTime? now,
  }) {
    final DateTime currentTime = now ?? DateTime.now();
    final candidates = <StudyRecommendation>[];

    final practicedToday = progress.lastActiveDate == _dayKey(currentTime);

    // 1. Streak keeper — losing a streak is the most urgent thing.
    if (progress.streakDays > 0 && !practicedToday) {
      candidates.add(StudyRecommendation(
        kind: RecommendationKind.streakKeeper,
        title: 'Save your ${progress.streakDays}-day streak',
        subtitle: 'Finish one session today to keep it alive.',
      ));
    }

    // 2. Daily challenge — the recurring habit anchor.
    if (!dailyChallengeDoneToday) {
      candidates.add(const StudyRecommendation(
        kind: RecommendationKind.dailyChallenge,
        title: 'Take today\'s Daily Challenge',
        subtitle: '10 questions · beat the clock · +50 XP.',
      ));
    }

    // 3. Diagnostic nudge — only meaningful with some practice behind.
    if (progress.totalQuestions >= minQuestionsBeforeDiagnostic &&
        _isDiagnosticStale(weakAreas.diagnosticDates, currentTime)) {
      candidates.add(const StudyRecommendation(
        kind: RecommendationKind.diagnosticNudge,
        title: 'Map your strengths',
        subtitle: 'A ~15 min check-up sharpens your recommendations.',
      ));
    }

    // 4. Weak chapter drill — the engine's core purpose. Weakest chapter
    // (most attempts among the sub-threshold ones wins the slot).
    final weakest = _weakestActionableChapter(progress, weakAreas);
    if (weakest != null) {
      candidates.add(StudyRecommendation(
        kind: RecommendationKind.weakChapterDrill,
        title: 'Weakest chapter: ${weakest.chapter}',
        subtitle:
            '${weakest.accuracy.round()}% accuracy over ${weakest.attempts} questions — drill 10 now.',
        subject: weakest.subject,
        chapter: weakest.chapter,
      ));
    }

    // 5. Mistake review — a real backlog of unresolved misses.
    if (weakAreas.recentMistakes.length >= minMistakesForReview) {
      candidates.add(StudyRecommendation(
        kind: RecommendationKind.mistakeReview,
        title: 'Revisit ${weakAreas.recentMistakes.length} missed questions',
        subtitle: 'Fix the misconceptions while they\'re fresh.',
      ));
    }

    // 6. Momentum fallback — never return an empty list.
    if (candidates.isEmpty) {
      final subject = _leastPracticedSubject(progress);
      candidates.add(StudyRecommendation(
        kind: RecommendationKind.momentum,
        title: 'Build momentum in $subject',
        subtitle: 'A quick session keeps the graph climbing.',
        subject: subject,
      ));
    }

    return candidates.take(maxRecommendations).toList();
  }

  /// Convenience for UI callers: builds from the live services.
  static List<StudyRecommendation> buildForCurrentUser() {
    final progressService = UserProgressService.instance;
    final weakService = WeakAreaTrackingService.instance;
    return build(
      progress: progressService.current,
      weakAreas: weakService.current,
      dailyChallengeDoneToday: progressService.dailyChallengeCompletedToday(),
    );
  }

  // ── Helpers ──

  static bool _isDiagnosticStale(
    Map<String, String> diagnosticDates,
    DateTime now,
  ) {
    if (diagnosticDates.isEmpty) return true;
    // Stale if EVERY subject's diagnostic is missing or older than the
    // refresh window — one fresh diagnostic satisfies the map.
    final refreshWindow =
        now.subtract(const Duration(days: diagnosticRefreshDays));
    for (final dateKey in diagnosticDates.values) {
      final date = DateTime.tryParse(dateKey);
      if (date != null && date.isAfter(refreshWindow)) return false;
    }
    return true;
  }

  /// The weakest chapter that clears the honesty bar, or null. Picks the
  /// lowest-accuracy qualifying chapter, preferring more attempts on ties
  /// (same rationale as WeakAreaTrackingService.weakestChapters).
  static ChapterStat? _weakestActionableChapter(
    UserProgressData progress,
    WeakAreaData weakAreas,
  ) {
    ChapterStat? best;
    for (final stat in weakAreas.chapters.values) {
      if (stat.attempts < minAttemptsForWeakness) continue;
      if (stat.accuracy > weaknessAccuracyThreshold) continue;
      if (best == null ||
          stat.accuracy < best.accuracy ||
          (stat.accuracy == best.accuracy &&
              stat.attempts > best.attempts)) {
        best = stat;
      }
    }
    return best;
  }

  static String _leastPracticedSubject(UserProgressData progress) {
    String best = 'Physics';
    int bestCount = -1;
    for (final subject in const ['Physics', 'Chemistry', 'Biology']) {
      final count = progress.subjectStats[subject]?.totalQuestions ?? 0;
      if (bestCount == -1 || count < bestCount) {
        best = subject;
        bestCount = count;
      }
    }
    return best;
  }

  static String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}
