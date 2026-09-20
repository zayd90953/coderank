/**
 * Unit tests for the pure scoring engine (no I/O, no mocks needed).
 * XP and streak rules mirror `lib/shared/services/user_progress_service.dart`.
 */

import {
  scoreSession,
  nextStreak,
  mergeSubjectStats,
  diagnosticXp,
  type NormalizedRequest,
  type BankQuestion,
} from '../scoring';

const BANK = new Map<string, BankQuestion>([
  // 4-option questions
  ['NEET-0001', { subject: 'Physics', correctAnswer: 2, optionCount: 4, difficulty: 'Medium', active: true }],
  ['NEET-0002', { subject: 'Physics', correctAnswer: 0, optionCount: 4, difficulty: 'Hard', active: true }],
  // 3-option question (the bank has 67 of these)
  ['NEET-0003', { subject: 'Biology', correctAnswer: 1, optionCount: 3, difficulty: 'Medium', active: true }],
]);

function req(overrides: Partial<NormalizedRequest> = {}): NormalizedRequest {
  return {
    sessionId: 's1',
    sessionKind: 'practice',
    subject: 'Physics',
    questionIds: ['NEET-0001', 'NEET-0002'],
    selectedAnswers: { 'NEET-0001': 2, 'NEET-0002': 1 },
    timedOutQuestionIds: [],
    timestamp: new Date('2026-09-18T10:00:00+05:30'),
    isDailyChallenge: false,
    ...overrides,
  };
}

describe('scoreSession — counting (tests 8/9/10, 21/22)', () => {
  it('counts correct answers (test 8)', () => {
    // NEET-0001 correct index is 2 → selected 2 is correct.
    const s = scoreSession(req(), BANK);
    expect(s.correct).toBe(1);
  });

  it('counts wrong answers (test 9)', () => {
    // NEET-0002 correct index is 0 → selected 1 is wrong.
    const s = scoreSession(req(), BANK);
    expect(s.incorrect).toBe(1);
  });

  it('counts timed-out questions as unanswered (test 10)', () => {
    const s = scoreSession(
      req({
        questionIds: ['NEET-0001', 'NEET-0002', 'NEET-0003'],
        selectedAnswers: { 'NEET-0001': 2 },
        timedOutQuestionIds: ['NEET-0002', 'NEET-0003'],
      }),
      BANK,
    );
    expect(s.correct).toBe(1);
    expect(s.incorrect).toBe(0);
    expect(s.unanswered).toBe(2);
    expect(s.completedCount).toBe(3);
    expect(s.totalQuestions).toBe(3);
  });

  it('validates a 3-option question: index 2 in range, index 3 would be rejected upstream (test 21)', () => {
    const s = scoreSession(
      req({
        questionIds: ['NEET-0003'],
        selectedAnswers: { 'NEET-0003': 1 }, // correct index is 1
      }),
      BANK,
    );
    expect(s.correct).toBe(1);
    expect(s.incorrect).toBe(0);
  });

  it('validates a 4-option question end-to-end (test 22)', () => {
    const s = scoreSession(req(), BANK);
    expect(s.totalQuestions).toBe(2);
  });
});

describe('scoreSession — XP formula (tests 11/12/13/14)', () => {
  it('base formula: correct*15 + completed*5 (test 11)', () => {
    // 1 correct + 1 wrong completed = 15 + 10 = 25; accuracy 50 < 80 → no bonus.
    const s = scoreSession(req(), BANK);
    expect(s.sessionXp).toBe(25);
  });

  it('awards +30 at 80% accuracy with >=5 questions (test 12)', () => {
    // 4 of 5 correct = 80% accuracy, 5 completed.
    // XP = 4*15 + 5*5 + 30 = 60 + 25 + 30 = 115.
    const bank = new Map(BANK);
    for (let i = 0; i < 3; i++) {
      bank.set(`X${i}`, { subject: 'Physics', correctAnswer: 0, optionCount: 4, difficulty: 'Medium', active: true });
    }
    const s = scoreSession(
      req({
        questionIds: ['NEET-0001', 'X0', 'X1', 'X2', 'NEET-0002'],
        selectedAnswers: { 'NEET-0001': 2, X0: 0, X1: 0, X2: 0, 'NEET-0002': 1 },
      }),
      bank,
    );
    expect(s.correct).toBe(4);
    expect(Math.round(s.accuracy)).toBe(80);
    expect(s.sessionXp).toBe(115);
  });

  it('does NOT award +30 below 5 questions even at 100% (test 13)', () => {
    // 4/4 correct = 100% but only 4 questions: XP = 60 + 20 = 80 (no bonus).
    const bank = new Map(BANK);
    bank.set('X0', { subject: 'Physics', correctAnswer: 0, optionCount: 4, difficulty: 'Medium', active: true });
    const s = scoreSession(
      req({
        questionIds: ['NEET-0001', 'X0', 'NEET-0002', 'NEET-0003'],
        selectedAnswers: { 'NEET-0001': 2, X0: 0, 'NEET-0002': 0, 'NEET-0003': 1 },
      }),
      bank,
    );
    expect(s.correct).toBe(4);
    expect(s.accuracy).toBe(100);
    expect(s.sessionXp).toBe(80);
  });

  it('adds +50 for dailyChallenge (test 14)', () => {
    // Same answers as base test (25 XP) but as a daily: 25 + 50 = 75.
    const s = scoreSession(req({ sessionKind: 'dailyChallenge', isDailyChallenge: true, subject: 'Daily Challenge' }), BANK);
    expect(s.sessionXp).toBe(75);
  });

  it('diagnostic is flat +20 regardless of answers (test 15)', () => {
    expect(diagnosticXp()).toBe(20);
  });
});

describe('nextStreak — IST streak engine (tests 16/17)', () => {
  it('continues the streak when last active was yesterday (test 16)', () => {
    const r = nextStreak('2026-09-17', 6, '2026-09-18', '2026-09-17');
    expect(r).toEqual({ streakDays: 7, lastActiveDate: '2026-09-18' });
  });

  it('resets to 1 after a gap (test 17)', () => {
    const r = nextStreak('2026-09-14', 6, '2026-09-18', '2026-09-17');
    expect(r).toEqual({ streakDays: 1, lastActiveDate: '2026-09-18' });
  });

  it('keeps the streak unchanged for a second session the same day', () => {
    const r = nextStreak('2026-09-18', 7, '2026-09-18', '2026-09-17');
    expect(r).toEqual({ streakDays: 7, lastActiveDate: '2026-09-18' });
  });

  it('starts at 1 for a brand-new user', () => {
    const r = nextStreak('', 0, '2026-09-18', '2026-09-17');
    expect(r).toEqual({ streakDays: 1, lastActiveDate: '2026-09-18' });
  });
});

describe('mergeSubjectStats', () => {
  it('creates a synthetic subject key on first sight (client keying preserved)', () => {
    const stats = mergeSubjectStats({}, 'Mock Test', 45, 30);
    expect(stats['Mock Test']).toEqual({
      subject: 'Mock Test',
      totalQuestions: 45,
      correctAnswers: 30,
      sessionsCount: 1,
    });
  });

  it('accumulates into an existing key', () => {
    const stats = mergeSubjectStats(
      {
        Physics: { subject: 'Physics', totalQuestions: 10, correctAnswers: 5, sessionsCount: 2 },
      },
      'Physics',
      8,
      6,
    );
    expect(stats['Physics']).toEqual({
      subject: 'Physics',
      totalQuestions: 18,
      correctAnswers: 11,
      sessionsCount: 3,
    });
  });
});
