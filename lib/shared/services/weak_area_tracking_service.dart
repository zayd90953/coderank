import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/practice/models/question_model.dart';

/// R-3: Weak-area tracking service.
///
/// Tracks accuracy **per chapter** (per subject) from every answered
/// question, plus a bounded memory of recently-missed question IDs, so the
/// recommendation engine (R-5) can say "revisit these" and the diagnostic
/// test (R-4) can see which chapters are unproven.
///
/// Design notes:
///  * **Own storage key** (`coderank_weak_areas_v1`) — deliberately NOT
///    merged into the existing user-progress JSON. Existing installs
///    upgrade with zero migration risk, and a corrupted weak-area blob can
///    never take down XP/streak persistence.
///  * **Batched per session**: runners feed the whole finished session via
///    [recordQuestionOutcomes] (one read-modify-write per session, not per
///    question — this fires on the results path, same as recordSession).
///  * **Graceful degradation**: persistence failures are swallowed and
///    reported through the notifier only — recording an answer must never
///    crash a session, mirroring UserProgressService's error posture.
///  * **Chapter identity**: the app bank tags `chapter` directly; the
///    schema format (R-1) derives the same field, so both bank formats
///    feed this service through one `question.chapter` read.
///  * Subjects are never hard-coded here: whatever subjects/questions the
///    runners see is what gets tracked (defensive against bank changes).
class WeakAreaTrackingService {
  WeakAreaTrackingService._();

  static final WeakAreaTrackingService instance =
      WeakAreaTrackingService._();

  static const String _storageKey = 'coderank_weak_areas_v1';

  /// Bounded memory of recently-missed question IDs (wrong OR timed out),
  /// newest first. Capped so thousands of old misses can't bloat storage.
  static const int _maxRecentMistakes = 60;

  final ValueNotifier<WeakAreaData> weakAreasNotifier =
      ValueNotifier<WeakAreaData>(const WeakAreaData());

  WeakAreaData get current => weakAreasNotifier.value;

  /// Loads persisted weak-area state. Safe to call multiple times; the
  /// app calls this once at startup (main.dart), tests call it after
  /// seeding mock SharedPreferences.
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        weakAreasNotifier.value =
            WeakAreaData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
      } else {
        weakAreasNotifier.value = const WeakAreaData();
      }
    } catch (e) {
      debugPrint('Error initializing WeakAreaTrackingService: $e');
    }
  }

  /// Feeds one finished session's per-question outcomes.
  ///
  /// [outcomes]: `(question, isCorrect)` pairs — a timed-out question is
  /// fed as `isCorrect: false` (a miss is a miss for mastery purposes).
  /// One persistence write per call.
  Future<void> recordQuestionOutcomes(
    List<({QuestionModel question, bool isCorrect})> outcomes,
  ) async {
    if (outcomes.isEmpty) return;
    final data = current;

    final chapters = Map<String, ChapterStat>.from(data.chapters);
    final mistakes = List<String>.from(data.recentMistakes);

    for (final outcome in outcomes) {
      final question = outcome.question;
      final isCorrect = outcome.isCorrect;
      final key = '${question.subject}::${question.chapter}';
      final existing = chapters[key] ??
          ChapterStat(subject: question.subject, chapter: question.chapter);
      chapters[key] = existing.withAttempt(isCorrect: isCorrect);

      if (!isCorrect) {
        mistakes
          ..remove(question.id)
          ..insert(0, question.id);
      } else {
        // A later correct answer clears the mistake — the misconception
        // was fixed (retention check handled by re-encounter, not here).
        mistakes.remove(question.id);
      }
    }
    if (mistakes.length > _maxRecentMistakes) {
      mistakes.removeRange(_maxRecentMistakes, mistakes.length);
    }

    weakAreasNotifier.value = WeakAreaData(
      chapters: chapters,
      recentMistakes: mistakes,
      diagnosticDates: data.diagnosticDates,
    );
    await _persist();
  }

  /// Convenience for a single outcome (diagnostic flow, tests).
  Future<void> recordQuestionOutcome(
    QuestionModel question, {
    required bool isCorrect,
  }) =>
      recordQuestionOutcomes([(question: question, isCorrect: isCorrect)]);

  /// Chapter stats for [subject], weakest first: lowest accuracy, then
  /// MOST attempts (0% over 10 attempts is a far more reliable weakness
  /// signal than 0% over 1 — a single fluke miss shouldn't outrank a
  /// consistently failed chapter), then alphabetical for stability.
  /// Chapters with zero attempts never appear here — they come from
  /// [unattemptedChapters].
  List<ChapterStat> weakestChapters(String subject, {int? limit}) {
    final stats =
        current.chapters.values.where((s) => s.subject == subject).toList()
          ..sort((a, b) {
            final byAccuracy =
                a.accuracy.compareTo(b.accuracy); // ascending = worst first
            if (byAccuracy != 0) return byAccuracy;
            final byAttempts = b.attempts.compareTo(a.attempts); // more first
            if (byAttempts != 0) return byAttempts;
            return a.chapter.compareTo(b.chapter);
          });
    return limit == null ? stats : stats.take(limit).toList();
  }

  /// The [limit] most recently missed question IDs, newest first, that are
  /// still unresolved (not later answered correctly).
  List<String> recentMistakeIds({int? limit}) {
    final ids = current.recentMistakes;
    return limit == null ? List.unmodifiable(ids) : ids.take(limit).toList();
  }

  /// True when [questionId] is still an unresolved recent mistake.
  bool isRecentMistake(String questionId) =>
      current.recentMistakes.contains(questionId);

  /// Chapters the user has never attempted under [subject] — the
  /// diagnostic flow (R-4) uses this to find unproven ground.
  Future<Set<String>> unattemptedChapters(
    String subject,
    Set<String> allChapters,
  ) async {
    final attempted = current.chapters.values
        .where((s) => s.subject == subject && s.attempts > 0)
        .map((s) => s.chapter)
        .toSet();
    return allChapters.difference(attempted);
  }

  // ── R-4: diagnostic test bookkeeping ──
  // The date a subject's diagnostic was last completed lives here (not in
  // a third storage file) because the diagnostic exists to calibrate
  // exactly this data. Reset clears it with everything else.

  /// Stamps today as the day [subject]'s diagnostic was last completed.
  Future<void> markDiagnosticCompleted(String subject) async {
    final data = current;
    weakAreasNotifier.value = WeakAreaData(
      chapters: data.chapters,
      recentMistakes: data.recentMistakes,
      diagnosticDates: {
        ...data.diagnosticDates,
        subject: _todayKey(),
      },
    );
    await _persist();
  }

  /// The 'YYYY-MM-DD' key of the last completed diagnostic for [subject],
  /// or null if never taken.
  String? diagnosticDateFor(String subject) =>
      current.diagnosticDates[subject];

  static String _todayKey() {
    final now = DateTime.now();
    return
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Clears all weak-area state (wired to the profile "Reset progress"
  /// flow alongside the other stats resets).
  Future<void> reset() async {
    weakAreasNotifier.value = const WeakAreaData();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing WeakAreaTrackingService: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(current.toJson()),
      );
    } catch (e) {
      debugPrint('Error saving WeakAreaTrackingService: $e');
    }
  }
}

/// Per-chapter mastery stats.
class ChapterStat {
  final String subject;
  final String chapter;
  final int attempts; // answered (correct or wrong); timeouts count here too
  final int correct;

  const ChapterStat({
    required this.subject,
    required this.chapter,
    this.attempts = 0,
    this.correct = 0,
  });

  double get accuracy =>
      attempts > 0 ? (correct / attempts) * 100 : 0.0;

  bool get hasData => attempts > 0;

  ChapterStat withAttempt({required bool isCorrect}) => ChapterStat(
        subject: subject,
        chapter: chapter,
        attempts: attempts + 1,
        correct: correct + (isCorrect ? 1 : 0),
      );

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'chapter': chapter,
        'attempts': attempts,
        'correct': correct,
      };

  factory ChapterStat.fromJson(Map<String, dynamic> json) => ChapterStat(
        subject: json['subject'] as String,
        chapter: json['chapter'] as String,
        attempts: json['attempts'] as int? ?? 0,
        correct: json['correct'] as int? ?? 0,
      );
}

/// Root persisted state.
class WeakAreaData {
  final Map<String, ChapterStat> chapters; // key: "subject::chapter"
  final List<String> recentMistakes; // question IDs, newest first

  /// R-4: subject → 'YYYY-MM-DD' of the last completed diagnostic.
  final Map<String, String> diagnosticDates;

  const WeakAreaData({
    this.chapters = const {},
    this.recentMistakes = const [],
    this.diagnosticDates = const {},
  });

  Map<String, dynamic> toJson() => {
        'chapters': chapters.map((k, v) => MapEntry(k, v.toJson())),
        'recentMistakes': recentMistakes,
        'diagnosticDates': diagnosticDates,
      };

  factory WeakAreaData.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'] as Map<String, dynamic>? ?? const {};
    final rawMistakes = json['recentMistakes'] as List? ?? const [];
    final rawDates = json['diagnosticDates'] as Map<String, dynamic>? ?? const {};
    return WeakAreaData(
      chapters: rawChapters.map(
        (k, v) => MapEntry(
          k,
          ChapterStat.fromJson(v as Map<String, dynamic>),
        ),
      ),
      recentMistakes: rawMistakes.cast<String>().toList(),
      diagnosticDates: rawDates.map<String, String>(
        (k, v) => MapEntry(k, v as String),
      ),
    );
  }
}
