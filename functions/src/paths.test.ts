/**
 * Scaffold smoke tests.
 *
 * These prove ONLY that the TypeScript toolchain (tsc + ts-jest + jest)
 * compiles and runs this package, and pin the shared contract constants so
 * an accidental rename is caught before deploy. They do NOT test
 * verification behavior — see src/__tests__/ for those.
 */

import {
  FIRESTORE_PATHS,
  VERIFY_SESSION_FUNCTION_NAME,
  SESSION_KINDS,
  DAILY_CHALLENGE_BONUS_XP,
  DIAGNOSTIC_BONUS_XP,
  TIMEZONE,
} from './index';

describe('scaffold smoke: toolchain works', () => {
  it('compiles and runs TypeScript tests', () => {
    expect(true).toBe(true);
    expect(1 + 1).toBe(2);
  });
});

describe('scaffold smoke: trusted Firestore paths are pinned', () => {
  it('pins the trusted answer-key collection name', () => {
    expect(FIRESTORE_PATHS.questionBank).toBe('questionBank');
  });

  it('pins the precomputed daily-sets collection name', () => {
    expect(FIRESTORE_PATHS.dailyChallengeSets).toBe('dailyChallengeSets');
  });

  it('pins the per-user progress and session path templates', () => {
    expect(FIRESTORE_PATHS.userProgress).toBe('users/{uid}/progress');
    expect(FIRESTORE_PATHS.userSessions).toBe('users/{uid}/sessions/{sessionId}');
  });

  it('pins the callable function name the Flutter client will invoke', () => {
    expect(VERIFY_SESSION_FUNCTION_NAME).toBe('verifySession');
  });
});

describe('scaffold smoke: session contract constants', () => {
  it('pins the final session-kind union', () => {
    expect([...SESSION_KINDS]).toEqual([
      'practice',
      'dailyChallenge',
      'mockFull',
      'mockQuick',
      'diagnostic',
    ]);
  });

  it('pins the audited bonus XP values and timezone policy', () => {
    expect(DAILY_CHALLENGE_BONUS_XP).toBe(50);
    expect(DIAGNOSTIC_BONUS_XP).toBe(20);
    expect(TIMEZONE).toBe('Asia/Kolkata');
  });
});
