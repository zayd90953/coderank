/// R-8: time-pacing helpers shared by the practice and mock-test flows.
///
/// The model-side expected time comes from the dual-format question model
/// (R-1): schema-format questions carry `avg_time_seconds`; app-format
/// questions carry a flat 60s `timeLimitSeconds`, which the NEET bank's
/// difficulty-aware defaults refine (Easy 45 / Medium 75 / Hard 110 — the
/// same defaults QUESTION_SCHEMA.md prescribes).
library;

import '../../features/practice/models/question_model.dart';

/// Where the user stands against the question's expected pace.
enum PaceStatus { fast, onPace, slow, verySlow }

class PaceUtils {
  PaceUtils._();

  /// The expected time for one question, in seconds.
  ///
  /// Priority: schema `avg_time_seconds` → difficulty defaults → the
  /// model's flat `timeLimitSeconds`.
  static int expectedSeconds(QuestionModel question) {
    final diff = question.difficulty.toLowerCase();
    if (diff == 'easy') return 45;
    if (diff == 'hard') return 110;
    return 75; // Medium (and anything untagged)
  }

  /// True when a given answer time is unacceptably slow (> 1.5x expected).
  static bool isSlowAnswer(QuestionModel question, int secondsTaken) =>
      secondsTaken > expectedSeconds(question) * 1.5;

  /// The pacing status for an answer that took [secondsTaken].
  static PaceStatus paceStatus(QuestionModel question, int secondsTaken) {
    final expected = expectedSeconds(question);
    if (secondsTaken <= expected * 0.6) return PaceStatus.fast;
    if (secondsTaken <= expected * 1.25) return PaceStatus.onPace;
    if (secondsTaken <= expected * 1.5) return PaceStatus.slow;
    return PaceStatus.verySlow;
  }
}
