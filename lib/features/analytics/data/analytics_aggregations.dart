import '../../../shared/services/user_progress_service.dart';

/// A-5: pure-function aggregations over the user's [SessionRecord] history.
///
/// We don't extend [UserProgressData] for A-5 — instead we derive every
/// metric the analytics screen needs from the data we already persist
/// (session timestamps, per-session accuracy, and the per-subject
/// counters in [UserProgressData.subjectStats]).
///
/// All time-bucketing is local-time. "Today" means the day returned by
/// `DateTime.now()`; the seven "last 7 days" run from today backwards
/// (inclusive), regardless of whether the user has a session in any
/// given bucket.
class AnalyticsAggregations {
  AnalyticsAggregations._();

  /// Per-day rollup of the last [days] days, ending today. Index 0 is
  /// the oldest day, index `days - 1` is today.
  static List<DayRollup> last7Days(List<SessionRecord> history) =>
      _rollup(history, 7);

  /// Per-day rollup of the last [days] days, split into "recent" (the
  /// last N) and "previous" (the N before that). Used for the subject
  /// mastery trending indicator.
  static TrendWindow trendWindow(
    List<SessionRecord> history, {
    int recentDays = 7,
    int previousDays = 7,
  }) {
    return _trendWindowFiltered(history, recentDays: recentDays,
        previousDays: previousDays, subjectFilter: null);
  }

  /// Like [trendWindow] but only counts sessions whose [SessionRecord.subject]
  /// matches [subject] (case-insensitive contains). Used to attach a
  /// per-subject trend indicator on the Subject Mastery cards.
  static TrendWindow trendWindowForSubject(
    List<SessionRecord> history,
    String subject, {
    int recentDays = 7,
    int previousDays = 7,
  }) {
    return _trendWindowFiltered(
      history,
      recentDays: recentDays,
      previousDays: previousDays,
      subjectFilter: subject,
    );
  }

  static TrendWindow _trendWindowFiltered(
    List<SessionRecord> history, {
    required int recentDays,
    required int previousDays,
    String? subjectFilter,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final recentStart = today.subtract(Duration(days: recentDays - 1));
    final previousEnd = recentStart.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: previousDays - 1));

    final filtered = subjectFilter == null
        ? history
        : history
            .where((r) => r.subject
                .toLowerCase()
                .contains(subjectFilter.toLowerCase()))
            .toList();

    double sumAcc(List<SessionRecord> xs) =>
        xs.fold(0.0, (a, r) => a + r.accuracy);
    int sumQs(List<SessionRecord> xs) =>
        xs.fold(0, (a, r) => a + r.total);

    final recent = filtered
        .where((r) => !_before(r.timestamp, recentStart) &&
            !_after(r.timestamp, today))
        .toList();
    final previous = filtered
        .where((r) => !_before(r.timestamp, previousStart) &&
            !_after(r.timestamp, previousEnd))
        .toList();

    final recentAvg = recent.isEmpty ? null : sumAcc(recent) / recent.length;
    final previousAvg =
        previous.isEmpty ? null : sumAcc(previous) / previous.length;
    final recentQs = sumQs(recent);
    final previousQs = sumQs(previous);

    return TrendWindow(
      recentAvgAccuracy: recentAvg,
      previousAvgAccuracy: previousAvg,
      recentTotalQuestions: recentQs,
      previousTotalQuestions: previousQs,
    );
  }

  /// Returns the subject name with the **lowest** accuracy (rounded)
  /// among those that have at least [minQuestions] questions solved.
  /// Returns `null` if no subject meets the threshold.
  ///
  /// Tie-break: prefer the subject with more questions solved (more
  /// confidence in the signal).
  static String? weakestSubject(
    Map<String, SubjectStat> subjectStats, {
    int minQuestions = 20,
  }) {
    String? best;
    var bestAcc = 101.0; // lower is worse
    var bestQs = -1;
    for (final entry in subjectStats.entries) {
      final stat = entry.value;
      if (stat.totalQuestions < minQuestions) continue;
      final acc = stat.accuracy;
      if (acc < bestAcc ||
          (acc == bestAcc && stat.totalQuestions > bestQs)) {
        bestAcc = acc;
        bestQs = stat.totalQuestions;
        best = entry.key;
      }
    }
    return best;
  }

  // ── Internals ──────────────────────────────────────────────────────────

  static List<DayRollup> _rollup(List<SessionRecord> history, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Initialise every bucket to an empty rollup so gaps in history show
    // up as zero-session days instead of disappearing.
    final buckets = <DateTime, _MutableRollup>{};
    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      buckets[d] = _MutableRollup();
    }
    for (final r in history) {
      final ts = r.timestamp;
      final day = DateTime(ts.year, ts.month, ts.day);
      final bucket = buckets[day];
      if (bucket == null) continue; // outside our window
      bucket.sessions++;
      bucket.questions += r.total;
      bucket.accuracySum += r.accuracy;
    }
    final ordered = buckets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ordered
        .map(
          (e) => DayRollup(
            day: e.key,
            sessions: e.value.sessions,
            questions: e.value.questions,
            avgAccuracy: e.value.sessions == 0
                ? null
                : e.value.accuracySum / e.value.sessions,
          ),
        )
        .toList(growable: false);
  }

  static bool _before(DateTime ts, DateTime cutoff) =>
      DateTime(ts.year, ts.month, ts.day).isBefore(cutoff);

  static bool _after(DateTime ts, DateTime cutoff) =>
      DateTime(ts.year, ts.month, ts.day).isAfter(cutoff);
}

class DayRollup {
  final DateTime day;
  final int sessions;
  final int questions;
  final double? avgAccuracy;

  const DayRollup({
    required this.day,
    required this.sessions,
    required this.questions,
    required this.avgAccuracy,
  });

  bool get hasActivity => sessions > 0;
}

class TrendWindow {
  final double? recentAvgAccuracy;
  final double? previousAvgAccuracy;
  final int recentTotalQuestions;
  final int previousTotalQuestions;

  const TrendWindow({
    required this.recentAvgAccuracy,
    required this.previousAvgAccuracy,
    required this.recentTotalQuestions,
    required this.previousTotalQuestions,
  });

  /// "up" if recent accuracy is at least 4 points higher than previous,
  /// "down" if it's at least 4 points lower, "steady" otherwise.
  /// Returns `null` if either side lacks enough data to compare.
  TrendDirection? direction() {
    final r = recentAvgAccuracy;
    final p = previousAvgAccuracy;
    if (r == null || p == null) return null;
    if (recentTotalQuestions < 5 || previousTotalQuestions < 5) return null;
    final delta = r - p;
    if (delta >= 4) return TrendDirection.up;
    if (delta <= -4) return TrendDirection.down;
    return TrendDirection.steady;
  }
}

enum TrendDirection { up, down, steady }

class _MutableRollup {
  int sessions = 0;
  int questions = 0;
  double accuracySum = 0;
}
