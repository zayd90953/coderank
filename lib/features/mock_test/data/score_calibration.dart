/// R-9: mock test scoring calibration.
///
/// The raw NEET score (+4 / −1 / 0) answers "how did THIS attempt go".
/// Calibration answers the question students actually care about:
/// "what does this pace predict for the real exam if I keep it up?"
///
/// Three calibrated outputs, all with honest uncertainty:
///   * **Projected score** — current net marks per attempted question,
///     projected across the unanswered remainder. Skipping questions is
///     the single biggest score leak at NEET; this makes the cost of
///     leaving the paper incomplete visible.
///   * **Predicted percentile band** — the score fraction is mapped
///     through a coarse monotone curve distilled from published NEET
///     score-vs-percentile distributions (2019–2024 trend midpoints).
///     It is deliberately approximate; the band widens when few questions
///     were attempted so thin data never masquerades as precision.
///   * **Predicted AIR** — derived from the band midpoint against the
///     historical candidate pool (~2.3M). Only shown past a meaningful
///     attempt size (see [minAttemptedForAir]).
///
/// Pure Dart, no Flutter, no I/O — fully unit-testable.
library;

class ScoreCalibration {
  /// Coarse score-fraction → percentile anchors (monotone), distilled
  /// from public NEET score-vs-percentile distributions. Deliberately
  /// round numbers: this is a trend line, not a promise.
  static const List<(double, double)> _percentileCurve = [
    (0.00, 1.0),
    (0.20, 10.0),
    (0.35, 35.0),
    (0.50, 60.0),
    (0.60, 80.0),
    (0.70, 92.0),
    (0.80, 98.0),
    (0.90, 99.7),
    (1.00, 99.99),
  ];

  /// Historical all-India candidate pool used for AIR estimates.
  static const int candidatePool = 2300000;

  /// AIR prediction needs at least a quarter of a full paper attempted —
  /// below that the estimate is noise.
  static const int minAttemptedForAir = 45;

  /// Percentile display needs at least this many attempts.
  static const int minAttemptedForPercentile = 10;

  final int totalQuestions;
  final int maxScore;
  final int attempted;
  final int rawScore;

  /// Net marks per attempted question (can be negative with bad guessing).
  final double perAttemptMark;

  /// Current raw score projected across the full paper at this pace.
  final int projectedScore;

  /// Predicted percentile: low / midpoint / high of the uncertainty band.
  final double percentileLow;
  final double percentileMid;
  final double percentileHigh;

  /// One-line plain-English uncertainty note for the UI.
  final String confidenceNote;

  /// Predicted All-India Rank from the band midpoint (null below the
  /// attempt threshold — the estimate would be noise).
  final int? predictedAir;

  /// Predicted AIR band edges, for display "AIR ~ a–b".
  final int? predictedAirLow;
  final int? predictedAirHigh;

  const ScoreCalibration._({
    required this.totalQuestions,
    required this.maxScore,
    required this.attempted,
    required this.rawScore,
    required this.perAttemptMark,
    required this.projectedScore,
    required this.percentileLow,
    required this.percentileMid,
    required this.percentileHigh,
    required this.confidenceNote,
    required this.predictedAir,
    required this.predictedAirLow,
    required this.predictedAirHigh,
  });

  /// Builds a calibration from one finished attempt.
  ///
  /// [attempted] = answered (correct or wrong) count; skipped questions
  /// are the projection pool. Returns null when nothing was attempted —
  /// there is nothing to calibrate from.
  static ScoreCalibration? from({
    required int correct,
    required int wrong,
    required int totalQuestions,
  }) {
    final attempted = correct + wrong;
    if (attempted <= 0) return null;

    final maxScore = totalQuestions * 4;
    final rawScore = correct * 4 - wrong;
    final perAttemptMark = rawScore / attempted;
    final unattempted = totalQuestions - attempted;

    // Projection: the current pace applied to the untouched remainder,
    // clamped to the achievable floor (all-wrong remainder) and ceiling.
    final projected = rawScore + perAttemptMark * unattempted;
    final projectedScore = projected.round().clamp(-unattempted, maxScore);

    // Uncertainty: fewer attempts → wider band. The band half-width in
    // score-fraction terms shrinks with sqrt(attempted / total).
    final fraction = (projectedScore / maxScore).clamp(-1.0, 1.0);
    final spread = _bandSpread(attempted, totalQuestions);
    final mid = _fractionToPercentile(fraction);
    final low = _fractionToPercentile((fraction - spread).clamp(-1.0, 1.0));
    final high = _fractionToPercentile((fraction + spread).clamp(-1.0, 1.0));

    final String note;
    if (attempted >= totalQuestions * 3 / 4) {
      note = 'Based on a nearly complete paper — tight estimate.';
    } else if (attempted >= totalQuestions / 2) {
      note = 'Based on over half the paper — reasonable estimate.';
    } else if (attempted >= minAttemptedForPercentile) {
      note = 'Few questions attempted — the real range is wide.';
    } else {
      note = 'Very little data — take this as a rough signal only.';
    }

    final int? air;
    final int? airLow;
    final int? airHigh;
    if (attempted >= minAttemptedForAir) {
      air = _percentileToAir(mid);
      airLow = _percentileToAir(high); // better percentile → better (lower) rank
      airHigh = _percentileToAir(low);
    } else {
      air = null;
      airLow = null;
      airHigh = null;
    }

    return ScoreCalibration._(
      totalQuestions: totalQuestions,
      maxScore: maxScore,
      attempted: attempted,
      rawScore: rawScore,
      perAttemptMark: perAttemptMark,
      projectedScore: projectedScore,
      percentileLow: low,
      percentileMid: mid,
      percentileHigh: high,
      confidenceNote: note,
      predictedAir: air,
      predictedAirLow: airLow,
      predictedAirHigh: airHigh,
    );
  }

  /// Score-fraction uncertainty half-width, shrinking with attempt share.
  static double _bandSpread(int attempted, int totalQuestions) {
    final share = (attempted / totalQuestions).clamp(0.0, 1.0);
    // Full paper → ±2% fraction; quarter paper → ±4%; thin data → wider.
    return 0.02 + 0.02 * (1 - share);
  }

  /// Monotone piecewise-linear interpolation of the historical curve.
  static double _fractionToPercentile(double fraction) {
    final f = fraction.clamp(0.0, 1.0);
    for (var i = 0; i < _percentileCurve.length - 1; i++) {
      final (f0, p0) = _percentileCurve[i];
      final (f1, p1) = _percentileCurve[i + 1];
      if (f <= f1) {
        if (f1 == f0) return p1;
        final t = (f - f0) / (f1 - f0);
        return p0 + t * (p1 - p0);
      }
    }
    return _percentileCurve.last.$2;
  }

  /// Percentile (0–100) → All-India Rank against the historical pool.
  static int _percentileToAir(double percentile) {
    final share = ((100 - percentile) / 100).clamp(0.0, 1.0);
    return (share * candidatePool).round().clamp(1, candidatePool);
  }
}
