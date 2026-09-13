// R-5 regression tests: the recommendation engine (pure logic).
//
//   * Streak keeper fires only with a live streak and nothing today.
//   * Daily challenge recommendation tracks the done-today flag.
//   * Diagnostic nudge respects the data minimum and staleness window.
//   * Weak-chapter drill respects honesty thresholds (>= 4 attempts,
//     <= 60% accuracy) and picks the truly weakest chapter.
//   * Mistake review fires at the backlog threshold.
//   * Momentum fallback when nothing qualifies; hard cap of 3 results.

import 'package:flutter_test/flutter_test.dart';

import 'package:coderank/features/recommendations/data/recommendation_engine.dart';
import 'package:coderank/shared/services/user_progress_service.dart';
import 'package:coderank/shared/services/weak_area_tracking_service.dart';

UserProgressData progress({
  int streak = 0,
  String lastActive = '',
  int totalQuestions = 0,
  Map<String, SubjectStat> subjectStats = const {},
}) =>
    UserProgressData(
      streakDays: streak,
      lastActiveDate: lastActive,
      totalQuestions: totalQuestions,
      subjectStats: subjectStats,
    );

void main() {
  // A fixed "now" so date logic is deterministic: 2026-09-13.
  final now = DateTime(2026, 9, 13);
  final todayKey = '2026-09-13';
  final yesterdayKey = '2026-09-12';

  group('streak keeper', () {
    test('fires with a live streak and no practice today', () {
      final recs = RecommendationEngine.build(
        progress: progress(streak: 5, lastActive: yesterdayKey),
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: false,
        now: now,
      );
      final keeper = recs.firstWhere(
        (r) => r.kind == RecommendationKind.streakKeeper,
      );
      expect(keeper.title, contains('5-day'));
    });

    test('does not fire when today is already practiced', () {
      final recs = RecommendationEngine.build(
        progress: progress(streak: 5, lastActive: todayKey),
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: false,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.streakKeeper),
        isFalse,
      );
    });

    test('does not fire with a zero streak', () {
      final recs = RecommendationEngine.build(
        progress: progress(streak: 0, lastActive: ''),
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: false,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.streakKeeper),
        isFalse,
      );
    });
  });

  group('daily challenge', () {
    test('fires when not done today', () {
      final recs = RecommendationEngine.build(
        progress: progress(streak: 1, lastActive: yesterdayKey),
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: false,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.dailyChallenge),
        isTrue,
      );
    });

    test('suppressed when done today', () {
      final recs = RecommendationEngine.build(
        progress: progress(streak: 1, lastActive: todayKey),
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: true,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.dailyChallenge),
        isFalse,
      );
    });
  });

  group('diagnostic nudge', () {
    test('respects the minimum-questions bar', () {
      final recs = RecommendationEngine.build(
        progress: progress(totalQuestions: 5),
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: true,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.diagnosticNudge),
        isFalse,
      );
    });

    test('fires when threshold met and no diagnostic ever taken', () {
      final recs = RecommendationEngine.build(
        progress: progress(totalQuestions: 50),
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: true,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.diagnosticNudge),
        isTrue,
      );
    });

    test('suppressed while any subject diagnostic is fresh', () {
      final recs = RecommendationEngine.build(
        progress: progress(totalQuestions: 50),
        weakAreas: const WeakAreaData(diagnosticDates: {
          'Physics': '2026-09-05', // 8 days ago — fresh
        }),
        dailyChallengeDoneToday: true,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.diagnosticNudge),
        isFalse,
      );
    });

    test('fires again after the refresh window passes', () {
      final recs = RecommendationEngine.build(
        progress: progress(totalQuestions: 50),
        weakAreas: const WeakAreaData(diagnosticDates: {
          'Physics': '2026-08-01', // > 14 days ago — stale
        }),
        dailyChallengeDoneToday: true,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.diagnosticNudge),
        isTrue,
      );
    });
  });

  group('weak chapter drill', () {
    test('fires only past the honesty thresholds, picks the weakest', () {
      final weakAreas = const WeakAreaData(chapters: {
        // Under the attempt bar — must NOT be recommended.
        'Physics::Shaky but new': ChapterStat(
            subject: 'Physics', chapter: 'Shaky but new',
            attempts: 2, correct: 0),
        // Above the accuracy bar — must NOT be recommended.
        'Physics::Strong chapter': ChapterStat(
            subject: 'Physics', chapter: 'Strong chapter',
            attempts: 10, correct: 9),
        // Qualifies: 4 attempts, 50%.
        'Physics::Trig chapter': ChapterStat(
            subject: 'Physics', chapter: 'Trig chapter',
            attempts: 4, correct: 2),
        // Qualifies and is weaker: 8 attempts, 25%.
        'Physics::Optics chapter': ChapterStat(
            subject: 'Physics', chapter: 'Optics chapter',
            attempts: 8, correct: 2),
      });

      final recs = RecommendationEngine.build(
        progress: progress(totalQuestions: 100),
        weakAreas: weakAreas,
        dailyChallengeDoneToday: true,
        now: now,
      );

      final drills = recs
          .where((r) => r.kind == RecommendationKind.weakChapterDrill)
          .toList();
      expect(drills.length, 1);
      expect(drills.single.chapter, 'Optics chapter');
      expect(drills.single.subject, 'Physics');
      expect(drills.single.subtitle, contains('25%'));
    });
  });

  group('mistake review', () {
    test('fires at the backlog threshold with a count', () {
      const weakAreas = WeakAreaData(
        recentMistakes: ['Q1', 'Q2', 'Q3', 'Q4', 'Q5'],
      );
      final recs = RecommendationEngine.build(
        progress: progress(totalQuestions: 100),
        weakAreas: weakAreas,
        dailyChallengeDoneToday: true,
        now: now,
      );
      final review = recs.firstWhere(
        (r) => r.kind == RecommendationKind.mistakeReview,
      );
      expect(review.title, contains('5 missed'));
    });

    test('stays quiet below the threshold', () {
      const weakAreas = WeakAreaData(recentMistakes: ['Q1', 'Q2']);
      final recs = RecommendationEngine.build(
        progress: progress(totalQuestions: 100),
        weakAreas: weakAreas,
        dailyChallengeDoneToday: true,
        now: now,
      );
      expect(
        recs.any((r) => r.kind == RecommendationKind.mistakeReview),
        isFalse,
      );
    });
  });

  group('fallback and cap', () {
    test('momentum fallback when nothing else qualifies', () {
      final recs = RecommendationEngine.build(
        progress: progress(), // brand-new user
        weakAreas: const WeakAreaData(),
        dailyChallengeDoneToday: true, // done — removes the daily rec
        now: now,
      );
      expect(recs, hasLength(1));
      expect(recs.single.kind, RecommendationKind.momentum);
      expect(recs.single.subject, isNotNull);
    });

    test('never returns more than maxRecommendations', () {
      // Everything fires at once.
      final weakAreas = const WeakAreaData(
        chapters: {
          'Physics::Optics': ChapterStat(
              subject: 'Physics', chapter: 'Optics',
              attempts: 8, correct: 2),
        },
        recentMistakes: ['Q1', 'Q2', 'Q3', 'Q4', 'Q5'],
      );
      final recs = RecommendationEngine.build(
        progress: progress(streak: 3, lastActive: yesterdayKey,
            totalQuestions: 100),
        weakAreas: weakAreas,
        dailyChallengeDoneToday: false,
        now: now,
      );
      expect(recs.length, RecommendationEngine.maxRecommendations);
      // Urgency order: streak first.
      expect(recs.first.kind, RecommendationKind.streakKeeper);
    });
  });
}
