import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

import '../models/question_model.dart';

class QuestionRepository {
  static const String _questionsPath =
      'lib/features/practice/data/questions.json';

  Future<List<QuestionModel>> _loadQuestions() async {
    final jsonString = await rootBundle.loadString(_questionsPath);

    final List<dynamic> jsonData = jsonDecode(jsonString);

    return jsonData
        .map(
          (json) => QuestionModel.fromJson(
        json as Map<String, dynamic>,
      ),
    )
        .toList();
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

  /// Compose a NEET-style mock test paper: `[Physics] [Chemistry] [Biology]`,
  /// in that order, with each section capped at the requested count.
  ///
  /// If a subject's pool has fewer questions than [physicsCount] / [chemCount]
  /// / [bioCount], the available questions are returned and the section is
  /// simply shorter. The total length is therefore bounded by the size of the
  /// underlying pool, never inflated with duplicates.
  Future<List<QuestionModel>> getMockTestQuestions({
    required int physicsCount,
    required int chemCount,
    required int bioCount,
  }) async {
    final all = await _loadQuestions();

    final physics = all
        .where((q) => q.subject == 'Physics')
        .take(physicsCount)
        .toList();
    final chemistry = all
        .where((q) => q.subject == 'Chemistry')
        .take(chemCount)
        .toList();
    final biology = all
        .where((q) => q.subject == 'Biology')
        .take(bioCount)
        .toList();

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