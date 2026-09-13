// B-5 regression tests: percentile / AIR ranking is gated until the user
// has answered 100 questions. Below the gate the estimates are suppressed
// ("Unranked" / "Locked"); at the gate they become meaningful.

import 'package:flutter_test/flutter_test.dart';
import 'package:coderank/shared/services/user_progress_service.dart';

const _gated = UserProgressData(totalQuestions: 42, totalCorrect: 30);
const _justBelow = UserProgressData(totalQuestions: 99, totalCorrect: 60);
const _atGate = UserProgressData(totalQuestions: 100, totalCorrect: 60);
const _beyond = UserProgressData(totalQuestions: 250, totalCorrect: 200);

void main() {
  group('B-5 ranking gate boundaries', () {
    test('isRankingUnlocked flips exactly at 100 questions', () {
      expect(UserProgressData().isRankingUnlocked, isFalse);
      expect(_gated.isRankingUnlocked, isFalse);
      expect(_justBelow.isRankingUnlocked, isFalse);
      expect(_atGate.isRankingUnlocked, isTrue);
      expect(_beyond.isRankingUnlocked, isTrue);
    });

    test('rankingQuestionsRemaining counts down to 0', () {
      expect(UserProgressData().rankingQuestionsRemaining, 100);
      expect(_gated.rankingQuestionsRemaining, 58);
      expect(_justBelow.rankingQuestionsRemaining, 1);
      expect(_atGate.rankingQuestionsRemaining, 0);
      expect(_beyond.rankingQuestionsRemaining, 0);
    });

    test('percentile is Unranked below the gate, banded above it', () {
      expect(UserProgressData().percentile, 'Unranked');
      expect(_gated.percentile, 'Unranked');
      expect(_justBelow.percentile, 'Unranked');

      // 60% accuracy at the gate → Top 25% band (60–70% → Top 15%? No:
      // 60 < 60 is false → Top 15% starts at exactly 60).
      expect(_atGate.percentile, isNot('Unranked'));
      expect(_beyond.percentile, isNot('Unranked'));
    });

    test('predictedAir is Locked below the gate, numeric above it', () {
      expect(UserProgressData().predictedAir, 'Locked');
      expect(_gated.predictedAir, 'Locked');
      expect(_justBelow.predictedAir, 'Locked');

      // 80% accuracy × 7.2 → 576 → AIR #8,400 band.
      expect(_beyond.predictedAir, 'AIR #8,400');
      expect(_atGate.predictedAir, startsWith('AIR '));
    });
  });
}
