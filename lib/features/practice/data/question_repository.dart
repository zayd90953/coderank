import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import '../models/question_model.dart';

class QuestionRepository {
  static const String _questionsPath =
      'lib/features/practice/data/questions.json';

  /// Lazily-parsed copy of the ~2,200-question bank (post AUD-1 dedupe),
  /// [QuestionRepository] instance. Without this, each practice / mock /
  /// daily-challenge launch re-reads and re-parses the whole JSON file.
  /// Callers must treat the returned lists as read-only (none mutate them).
  static List<QuestionModel>? _cachedQuestions;

  Future<List<QuestionModel>> _loadQuestions() async {
    final cached = _cachedQuestions;
    if (cached != null) return cached;

    final jsonString = await rootBundle.loadString(_questionsPath);

    final List<dynamic> jsonData = jsonDecode(jsonString);

    final questions = jsonData
        .map(
          (json) => QuestionModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
    _cachedQuestions = questions;
    return questions;
  }

  Future<List<QuestionModel>> getQuestionsBySubject(
      String subject,
      ) async {
    final questions = await _loadQuestions();

    return questions
        .where((question) => question.subject == subject)
        .toList();
  }

  /// Return every question in the bank, regardless of subject.
  Future<List<QuestionModel>> getAllQuestions() async {
    return _loadQuestions();
  }

  // ── R-2: chapter / topic / bloom-level queries (tutoring engine) ──
  //
  // All of these run over the same cached bank. Note: the current 2,229-
  // question app-format bank has no topic/bloom tagging, so topic/bloom
  // filters match nothing in it today — they become meaningful the moment
  // schema-format questions (demo bank or future tagged uploads) land in
  // the bank file. Chapter filtering works on both formats: the app bank
  // tags `chapter`, and schema questions derive everything the model
  // needs. Query helpers tolerate nulls rather than throwing.

  /// All questions of [subject] within [chapter] (exact NCERT chapter
  /// name, e.g. "Human Reproduction"). Case-sensitive, matching the bank.
  Future<List<QuestionModel>> getQuestionsByChapter(
    String subject,
    String chapter,
  ) async {
    final questions = await _loadQuestions();
    return questions
        .where((q) => q.subject == subject && q.chapter == chapter)
        .toList();
  }

  /// All questions of [subject] whose schema-format topic matches
  /// [topic] (sub-topic within a chapter). App-format questions have no
  /// topic and never match.
  Future<List<QuestionModel>> getQuestionsByTopic(
    String subject,
    String topic,
  ) async {
    final questions = await _loadQuestions();
    return questions
        .where(
          (q) =>
              q.subject == subject && q.topic != null && q.topic == topic,
        )
        .toList();
  }

  /// All questions of [subject] at the given bloom level
  /// (`recall` / `application` / `analysis`). App-format questions have
  /// no bloom tag and never match.
  Future<List<QuestionModel>> getQuestionsByBloomLevel(
    String subject,
    String bloomLevel,
  ) async {
    final questions = await _loadQuestions();
    return questions
        .where(
          (q) =>
              q.subject == subject &&
              q.bloomLevel != null &&
              q.bloomLevel == bloomLevel,
        )
        .toList();
  }

  /// The question with [id], or null when the bank doesn't contain it.
  /// Linear scan over the cached bank — callers pass at most a handful of
  /// IDs (mistake review), so a map isn't worth the memory.
  Future<QuestionModel?> getQuestionById(String id) async {
    final questions = await _loadQuestions();
    for (final q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }

  /// Every NCERT chapter that has at least one question for [subject],
  /// with its question count, sorted alphabetically. Feeds the diagnostic
  /// test (R-4) and weak-area tracking (R-3).
  Future<Map<String, int>> getChapterCoverage(String subject) async {
    final questions = await _loadQuestions();
    final counts = <String, int>{};
    for (final q in questions.where((q) => q.subject == subject)) {
      counts[q.chapter] = (counts[q.chapter] ?? 0) + 1;
    }
    final keys = counts.keys.toList()..sort();
    return {for (final k in keys) k: counts[k]!};
  }

  /// The distinct schema-format topics within [subject] + [chapter]
  /// (sorted). Empty for app-format-only chapters.
  Future<List<String>> getTopicsForChapter(
    String subject,
    String chapter,
  ) async {
    final questions = await _loadQuestions();
    final topics = questions
        .where(
          (q) =>
              q.subject == subject &&
              q.chapter == chapter &&
              q.topic != null,
        )
        .map((q) => q.topic!)
        .toSet()
        .toList()
      ..sort();
    return topics;
  }

  /// Compose a NEET-style mock test paper: `[Physics] [Chemistry] [Biology]`,
  /// in that order, with each section capped at the requested count.
  ///
  /// Each subject's pool is **shuffled before capping**, so every call
  /// returns a different spread of questions — retaking a mock test no
  /// longer serves the identical paper. If a subject's pool has fewer
  /// questions than [physicsCount] / [chemCount] / [bioCount], the
  /// available questions are returned and the section is simply shorter.
  /// The total length is therefore bounded by the size of the underlying
  /// pool, never inflated with duplicates.
  ///
  /// (Optional [seed] makes the selection deterministic — used by tests
  /// to pin an otherwise random shuffle.)
  Future<List<QuestionModel>> getMockTestQuestions({
    required int physicsCount,
    required int chemCount,
    required int bioCount,
    int? seed,
  }) async {
    final all = await _loadQuestions();
    final rng = seed == null ? Random() : Random(seed);

    List<QuestionModel> draw(String subject, int count) {
      final pool = all.where((q) => q.subject == subject).toList()
        ..shuffle(rng);
      return pool.take(count).toList();
    }

    final physics = draw('Physics', physicsCount);
    final chemistry = draw('Chemistry', chemCount);
    final biology = draw('Biology', bioCount);

    return [...physics, ...chemistry, ...biology];
  }

  /// Daily NEET Challenge selector (A-3).
  ///
  /// Returns exactly 10 high-yield questions for the given [date]
  /// (defaults to `DateTime.now()`):
  ///   * 4 Biology
  ///   * 3 Physics
  ///   * 3 Chemistry
  ///
  /// Filters out `Easy` difficulty to match the "high-yield NEET" framing
  /// on the launcher card. Selection is **deterministic per date** —
  /// every user on the same calendar date gets the same 10 questions, so
  /// it's a shared experience without a backend.
  ///
  /// The seed is the local `YYYYMMDD` integer. Each subject draws its
  /// target count from a per-subject bucket using a sub-seed so the
  /// sub-selections stay stable even if one subject's bucket is empty.
  /// The final 10 are then order-shuffled with the date seed so the
  /// question order isn't grouped by subject.
  Future<List<QuestionModel>> getDailyChallengeQuestions({
    DateTime? date,
  }) async {
    final day = date ?? DateTime.now();
    final dateKey = day.year * 10000 + day.month * 100 + day.day;
    final rng = Random(dateKey);

    final all = await _loadQuestions();
    final highYield = all.where((q) => q.difficulty != 'Easy').toList();

    final bio = highYield.where((q) => q.subject == 'Biology').toList();
    final phy = highYield.where((q) => q.subject == 'Physics').toList();
    final chem = highYield.where((q) => q.subject == 'Chemistry').toList();

    /// Per-slot picker: each call is seeded with a *distinct* sub-seed
    /// (`slot * 7919` and +1 so the first hit isn't always the same
    /// question as `nextInt(bucket.length)` on the date seed), then
    /// walked forward until the candidate is not already in [taken].
    ///
    /// The `7919` prime keeps slots well-separated even when bucket
    /// sizes are small, and the forward walk guarantees the same
    /// (date, slot) always picks the same question — a stable daily
    /// for every user, with all 10 slots actually distinct.
    QuestionModel? pickAt(List<QuestionModel> bucket, int slot, Set<String> taken) {
      if (bucket.isEmpty) return null;
      final slotRng = Random(dateKey + slot * 7919 + 1);
      var start = slotRng.nextInt(bucket.length);
      for (var step = 0; step < bucket.length; step++) {
        final idx = (start + step) % bucket.length;
        final candidate = bucket[idx];
        if (!taken.contains(candidate.id)) {
          taken.add(candidate.id);
          return candidate;
        }
      }
      // Every question in the bucket is already taken — return null and
      // let the top-up loop below fill the slot.
      return null;
    }

    final taken = <String>{};
    final List<QuestionModel> picks = [];
    for (var i = 0; i < 4; i++) {
      final p = pickAt(bio, i, taken);
      if (p != null) picks.add(p);
    }
    for (var i = 0; i < 3; i++) {
      final p = pickAt(phy, i, taken);
      if (p != null) picks.add(p);
    }
    for (var i = 0; i < 3; i++) {
      final p = pickAt(chem, i, taken);
      if (p != null) picks.add(p);
    }

    // Order-shuffle so the 10 aren't grouped Bio/Phy/Chem.
    picks.shuffle(rng);

    // Top up to 10 if any subject bucket was empty (defensive — current
    // bank has 1000 Bio / 750 Phy / 750 Chem so this should not fire).
    if (picks.length < 10) {
      final seen = picks.map((q) => q.id).toSet();
      final fillers = highYield.where((q) => !seen.contains(q.id));
      for (final q in fillers) {
        if (picks.length >= 10) break;
        picks.add(q);
      }
    }

    return picks.take(10).toList();
  }
}