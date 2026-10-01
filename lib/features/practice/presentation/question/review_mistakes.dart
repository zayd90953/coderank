import 'dart:math';

import '../../../../shared/services/weak_area_tracking_service.dart';
import '../../data/question_repository.dart';
import '../../models/question_model.dart';
import 'question_screen.dart';

/// M-7: shared mistake-review launcher.
///
/// Resolves the R-3 service's recent unresolved-mistake IDs against the
/// bank and opens a [QuestionScreen] review session (exact-list override,
/// untimed, shuffled). A later correct answer resolves the mistake in the
/// R-3 memory — the list self-cleans as the student masters the misses.
///
/// One launcher, three entry points: the Practice Hub quick action, the
/// Home "REVIEW" recommendation card, and the results screens.
class ReviewMistakes {
  ReviewMistakes._();

  /// Resolves the current recent mistakes into session questions.
  ///
  /// Returns null when nothing is reviewable. Uses the same selection
  /// policy as the practice runner: shuffle, then cap at [limit].
  static Future<List<QuestionModel>?> resolveQuestions({int limit = 15}) async {
    final ids = WeakAreaTrackingService.instance.recentMistakeIds(limit: limit);
    if (ids.isEmpty) return null;

    final repo = QuestionRepository();
    final picked = <QuestionModel>[];
    for (final id in ids) {
      final q = await repo.getQuestionById(id);
      if (q != null) picked.add(q);
    }
    if (picked.isEmpty) {
      // All mistake IDs stale (e.g. bank changed) — nothing reviewable.
      return null;
    }
    picked.shuffle(Random());
    return picked;
  }

  /// Builds the review session screen from the current mistakes, or null
  /// when there is nothing to review.
  static Future<QuestionScreen?> buildScreen({int limit = 15}) async {
    final questions = await resolveQuestions(limit: limit);
    if (questions == null) return null;

    // Label the session by its majority subject (no fake "Review" key in
    // analytics — mirrors the diagnostic's no-pseudo-subject decision).
    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.subject] = (counts[q.subject] ?? 0) + 1;
    }
    var subject = questions.first.subject;
    var best = -1;
    counts.forEach((s, c) {
      if (c > best) {
        best = c;
        subject = s;
      }
    });

    return QuestionScreen(
      subject: subject,
      questionsOverride: questions,
      timeLimit: null,
    );
  }
}
