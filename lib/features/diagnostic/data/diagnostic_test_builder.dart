import 'dart:math';

import '../../practice/data/question_repository.dart';
import '../../practice/models/question_model.dart';

/// R-4: builds a diagnostic test set for a subject.
///
/// Goal: even coverage of the whole syllabus in one sitting, so the
/// weak-area engine (R-3) gets a per-chapter accuracy snapshot instead of
/// the lopsided view casual practice leaves behind.
///
/// Shape: up to [maxPerChapter] questions per chapter, drawn round-robin
/// across chapters (shuffled chapter order), capped at [maxTotal]. The
/// current bank has ~30 chapters per subject, so a full subject yields up
/// to 24 questions (~15 minutes) covering every chapter at least once.
/// Question order interleaves chapters automatically via the round-robin.
///
/// [seed] makes the draw deterministic (tests); production calls omit it.
class DiagnosticTestBuilder {
  DiagnosticTestBuilder._();

  static const int maxPerChapter = 2;
  static const int maxTotalQuestions = 24;

  static Future<List<QuestionModel>> buildSet(
    String subject, {
    int? seed,
    int maxPerChapter = maxPerChapter,
    int maxTotal = maxTotalQuestions,
  }) async {
    final repo = QuestionRepository();
    final coverage = await repo.getChapterCoverage(subject);
    if (coverage.isEmpty) return const [];

    final rng = Random(seed);
    final chapters = coverage.keys.toList()..shuffle(rng);

    // One shuffled pool per chapter, fetched once.
    final pools = <String, List<QuestionModel>>{};
    for (final chapter in chapters) {
      final pool = await repo.getQuestionsByChapter(subject, chapter)
        ..shuffle(rng);
      pools[chapter] = pool;
    }

    // Round-robin draw: every chapter contributes before any contributes
    // a second question — even coverage, and no duplicates.
    final picks = <QuestionModel>[];
    final used = <String>{};
    for (var round = 0;
        round < maxPerChapter && picks.length < maxTotal;
        round++) {
      for (final chapter in chapters) {
        if (picks.length >= maxTotal) break;
        QuestionModel? next;
        for (final q in pools[chapter]!) {
          if (!used.contains(q.id)) {
            next = q;
            break;
          }
        }
        if (next == null) continue; // chapter exhausted
        used.add(next.id);
        picks.add(next);
      }
    }
    return picks;
  }
}
