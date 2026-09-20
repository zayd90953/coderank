/**
 * verifySession unit tests — in-memory Firestore fake, no emulator, no
 * production Firestore, no credentials.
 *
 * firebase-admin / firebase-functions are mocked via functions/__mocks__/ so
 * the ESM-only transitive deps of the real SDKs are never loaded in Jest.
 */

import { HttpsError } from 'firebase-functions/v2/https';
import { handleVerifySession, type VerifyDeps } from '../verifySession';
import { FakeFirestore } from './fakes';

// ── Fixed server time: 2026-09-18 10:00 IST → today 2026-09-18 ───────────
const NOW = new Date('2026-09-18T10:00:00+05:30');
const TODAY = '2026-09-18';
const YESTERDAY = '2026-09-17';

const AUTH = { uid: 'userA', token: {} };

/** Trusted bank fixture (mirrors audited bank: 3- and 4-option questions). */
function seedBank(db: FakeFirestore): void {
  const bank: Record<string, { subject: string; correctAnswer: number; optionCount: number; difficulty: string; active: boolean }> = {
    'NEET-0001': { subject: 'Physics', correctAnswer: 2, optionCount: 4, difficulty: 'Medium', active: true },
    'NEET-0002': { subject: 'Physics', correctAnswer: 0, optionCount: 4, difficulty: 'Hard', active: true },
    'NEET-0003': { subject: 'Biology', correctAnswer: 1, optionCount: 3, difficulty: 'Medium', active: true }, // 3-option
    'NEET-0004': { subject: 'Chemistry', correctAnswer: 3, optionCount: 4, difficulty: 'Medium', active: true },
    'NEET-0005': { subject: 'Biology', correctAnswer: 1, optionCount: 4, difficulty: 'Medium', active: true },
    'NEET-0006': { subject: 'Physics', correctAnswer: 0, optionCount: 4, difficulty: 'Medium', active: false }, // retired
    'NEET-0007': { subject: 'Physics', correctAnswer: 1, optionCount: 4, difficulty: 'Medium', active: true },
  };
  for (const [id, doc] of Object.entries(bank)) {
    db.seed(`questionBank/${id}`, doc);
  }
}

/** Daily set for TODAY: 4 Bio + 3 Phy + 3 Chem (server-owned). */
function seedDailySet(db: FakeFirestore): string[] {
  const ids = ['BIO-1', 'BIO-2', 'BIO-3', 'BIO-4', 'PHY-1', 'PHY-2', 'PHY-3', 'CHE-1', 'CHE-2', 'CHE-3'];
  const subjects: Record<string, { subject: string; correctAnswer: number; optionCount: number; difficulty: string; active: boolean }> = {
    'BIO-1': { subject: 'Biology', correctAnswer: 0, optionCount: 4, difficulty: 'Hard', active: true },
    'BIO-2': { subject: 'Biology', correctAnswer: 1, optionCount: 4, difficulty: 'Medium', active: true },
    'BIO-3': { subject: 'Biology', correctAnswer: 2, optionCount: 4, difficulty: 'Medium', active: true },
    'BIO-4': { subject: 'Biology', correctAnswer: 3, optionCount: 4, difficulty: 'Hard', active: true },
    'PHY-1': { subject: 'Physics', correctAnswer: 1, optionCount: 4, difficulty: 'Hard', active: true },
    'PHY-2': { subject: 'Physics', correctAnswer: 2, optionCount: 4, difficulty: 'Medium', active: true },
    'PHY-3': { subject: 'Physics', correctAnswer: 0, optionCount: 4, difficulty: 'Hard', active: true },
    'CHE-1': { subject: 'Chemistry', correctAnswer: 3, optionCount: 4, difficulty: 'Medium', active: true },
    'CHE-2': { subject: 'Chemistry', correctAnswer: 0, optionCount: 4, difficulty: 'Hard', active: true },
    'CHE-3': { subject: 'Chemistry', correctAnswer: 1, optionCount: 4, difficulty: 'Medium', active: true },
  };
  for (const [id, doc] of Object.entries(subjects)) {
    db.seed(`questionBank/${id}`, doc);
  }
  db.seed(`dailyChallengeSets/${TODAY}`, { dateKey: TODAY, questionIds: ids, active: true });
  return ids;
}

function makeDeps(db: FakeFirestore): VerifyDeps {
  return { db, now: () => new Date(NOW) };
}

interface ReqOptions {
  sessionId?: string;
  sessionKind?: string;
  subject?: string;
  questionIds?: string[];
  selectedAnswers?: Record<string, number>;
  timedOutQuestionIds?: string[];
  timestamp?: string;
  isDailyChallenge?: boolean;
}

function baseReq(o: ReqOptions = {}): Record<string, unknown> {
  const questionIds = o.questionIds ?? ['NEET-0001', 'NEET-0002'];
  const selected = o.selectedAnswers ?? { 'NEET-0001': 2, 'NEET-0002': 1 };
  return {
    sessionId: o.sessionId ?? 'sess-001',
    sessionKind: o.sessionKind ?? 'practice',
    subject: o.subject ?? 'Physics',
    questionIds,
    selectedAnswers: selected,
    timedOutQuestionIds: o.timedOutQuestionIds ?? [],
    timestamp: o.timestamp ?? '2026-09-18T09:55:00+05:30',
    isDailyChallenge: o.isDailyChallenge ?? false,
  };
}

async function expectHttpsError(
  promise: Promise<unknown>,
  code: string,
): Promise<HttpsError> {
  try {
    await promise;
  } catch (e) {
    expect(e).toBeInstanceOf(HttpsError);
    const err = e as HttpsError;
    expect(err.code).toBe(code);
    return err;
  }
  throw new Error(`Expected HttpsError(${code}) but the call succeeded`);
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Authentication (test 1)
// ─────────────────────────────────────────────────────────────────────────────
describe('authentication', () => {
  it('rejects unauthenticated callers (test 1)', async () => {
    const db = new FakeFirestore();
    await expectHttpsError(
      handleVerifySession(baseReq(), undefined, makeDeps(db)),
      'unauthenticated',
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 2–7. Contract validation (tests 2/3/5/6/7 + timestamp tolerance)
// ─────────────────────────────────────────────────────────────────────────────
describe('request contract validation', () => {
  it('rejects a malformed request body (test 2)', async () => {
    const db = new FakeFirestore();
    await expectHttpsError(
      handleVerifySession('not-an-object', AUTH, makeDeps(db)),
      'invalid-argument',
    );
    await expectHttpsError(
      handleVerifySession({ sessionId: 42 }, AUTH, makeDeps(db)),
      'invalid-argument',
    );
    await expectHttpsError(
      handleVerifySession(baseReq({ questionIds: [] }), AUTH, makeDeps(db)),
      'invalid-argument',
    );
  });

  it('rejects duplicate question IDs (test 3)', async () => {
    const db = new FakeFirestore();
    await expectHttpsError(
      handleVerifySession(
        baseReq({ questionIds: ['NEET-0001', 'NEET-0001'], selectedAnswers: { 'NEET-0001': 2 } }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
  });

  it('rejects an out-of-range selected answer, including the 3-option edge (test 5, 21)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    // NEET-0003 has 3 options (valid indexes 0-2); index 3 must be rejected.
    await expectHttpsError(
      handleVerifySession(
        baseReq({
          subject: 'Biology',
          questionIds: ['NEET-0003'],
          selectedAnswers: { 'NEET-0003': 3 },
        }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
    // Negative index is also rejected by contract validation.
    await expectHttpsError(
      handleVerifySession(
        baseReq({ selectedAnswers: { 'NEET-0001': -1 } }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
  });

  it('rejects selected + timedOut overlap (test 6)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    await expectHttpsError(
      handleVerifySession(
        baseReq({
          selectedAnswers: { 'NEET-0001': 2 },
          timedOutQuestionIds: ['NEET-0001', 'NEET-0002'],
        }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
  });

  it('rejects a missing answer state (test 7)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    await expectHttpsError(
      handleVerifySession(
        baseReq({
          selectedAnswers: { 'NEET-0001': 2 }, // NEET-0002 in neither state
          timedOutQuestionIds: [],
        }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
  });

  it('rejects client timestamps that are too far in the future or too old', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    await expectHttpsError(
      handleVerifySession(
        baseReq({ timestamp: '2026-09-18T12:00:00+05:30' }), // > 10 min ahead
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
    await expectHttpsError(
      handleVerifySession(
        baseReq({ timestamp: '2026-09-16T09:00:00+05:30' }), // > 24h old
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
  });

  it('enforces per-kind consistency: dailyChallenge ⇔ isDailyChallenge', async () => {
    const db = new FakeFirestore();
    const ids = seedDailySet(db);
    const selected = Object.fromEntries(ids.map((id) => [id, 0]));

    // Daily without the flag → invalid.
    await expectHttpsError(
      handleVerifySession(
        baseReq({ sessionKind: 'dailyChallenge', subject: 'Daily Challenge', questionIds: ids, selectedAnswers: selected, isDailyChallenge: false }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
    // Non-daily with the flag → invalid.
    await expectHttpsError(
      handleVerifySession(baseReq({ isDailyChallenge: true }), AUTH, makeDeps(db)),
      'invalid-argument',
    );
  });

  it('enforces per-kind subject literals (mock/daily/diagnostic)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    await expectHttpsError(
      handleVerifySession(baseReq({ sessionKind: 'mockFull', subject: 'Physics' }), AUTH, makeDeps(db)),
      'invalid-argument',
    );
    await expectHttpsError(
      handleVerifySession(baseReq({ sessionKind: 'diagnostic', subject: 'Physics' }), AUTH, makeDeps(db)),
      'invalid-argument',
    );
    await expectHttpsError(
      handleVerifySession(baseReq({ sessionKind: 'practice', subject: 'Mock Test' }), AUTH, makeDeps(db)),
      'invalid-argument',
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 4–5, 23. Trusted bank verification
// ─────────────────────────────────────────────────────────────────────────────
describe('trusted bank verification', () => {
  it('rejects an unknown question ID (test 4)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    await expectHttpsError(
      handleVerifySession(baseReq({ questionIds: ['NEET-9999'], selectedAnswers: { 'NEET-9999': 0 } }), AUTH, makeDeps(db)),
      'not-found',
    );
  });

  it('rejects an inactive (retired) question', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    await expectHttpsError(
      handleVerifySession(baseReq({ questionIds: ['NEET-0006'], selectedAnswers: { 'NEET-0006': 0 } }), AUTH, makeDeps(db)),
      'failed-precondition',
    );
  });

  it('rejects subject mismatch against the bank (test 23)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    // Practice session claims Physics but NEET-0005 is a Biology question.
    await expectHttpsError(
      handleVerifySession(
        baseReq({ questionIds: ['NEET-0005'], selectedAnswers: { 'NEET-0005': 1 } }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
  });

  it('allows mixed-subject questions for mock sessions (no per-question subject rule)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    const res = await handleVerifySession(
      baseReq({
        sessionKind: 'mockQuick',
        subject: 'Mock Test',
        questionIds: ['NEET-0001', 'NEET-0005', 'NEET-0004'],
        selectedAnswers: { 'NEET-0001': 2, 'NEET-0005': 1, 'NEET-0004': 3 },
      }),
      AUTH,
      makeDeps(db),
    );
    expect(res.success).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 8–15. Scoring + XP written to Firestore (tests 8–15, 21, 22)
// ─────────────────────────────────────────────────────────────────────────────
describe('competitive session scoring and atomic write', () => {
  it('computes correct/incorrect/unanswered and base XP server-side (tests 8/9/10/11/22)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    // NEET-0001 correct (idx 2), NEET-0002 wrong (idx 1 vs 0).
    const res = await handleVerifySession(baseReq(), AUTH, makeDeps(db));

    expect(res.success).toBe(true);
    expect(res.xpGained).toBe(25); // 1*15 + 2*5; accuracy 50 < 80 → no bonus
    const rec = db.doc('users/userA/sessions/sess-001');
    expect(rec['correct']).toBe(1);
    expect(rec['total']).toBe(2);
    expect(rec['xpGained']).toBe(25);
    expect(rec['sessionKind']).toBe('practice');
    expect(rec['createdAt']).toEqual({ __sentinel: 'serverTimestamp' });

    const progress = db.doc('users/userA/progress/data');
    expect(progress['totalQuestions']).toBe(2);
    expect(progress['totalCorrect']).toBe(1);
    expect(progress['totalIncorrect']).toBe(1);
    expect(progress['totalUnanswered']).toBe(0);
    expect(progress['totalSessions']).toBe(1);
    expect(progress['xpPoints']).toBe(25);
    expect(progress['streakDays']).toBe(1);
    expect(progress['lastActiveDate']).toBe(TODAY);
    expect((progress['subjectStats'] as Record<string, unknown>)['Physics']).toEqual({
      subject: 'Physics', totalQuestions: 2, correctAnswers: 1, sessionsCount: 1,
    });
  });

  it('counts timed-out questions as unanswered (test 10, extended)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    await handleVerifySession(
      baseReq({
        questionIds: ['NEET-0001', 'NEET-0002', 'NEET-0007'],
        selectedAnswers: { 'NEET-0001': 2 }, // 1 correct
        timedOutQuestionIds: ['NEET-0002', 'NEET-0007'], // 2 unanswered
      }),
      AUTH,
      makeDeps(db),
    );
    const progress = db.doc('users/userA/progress/data');
    expect(progress['totalCorrect']).toBe(1);
    expect(progress['totalIncorrect']).toBe(0);
    expect(progress['totalUnanswered']).toBe(2);
    // XP: 1*15 + 3*5 = 30 (accuracy 33 < 80).
    expect(progress['xpPoints']).toBe(30);
  });

  it('awards the +30 bonus at 80% accuracy with >=5 questions (test 12)', async () => {
    const db = new FakeFirestore();
    const bank: Record<string, { subject: string; correctAnswer: number; optionCount: number; difficulty: string; active: boolean }> = {};
    for (let i = 1; i <= 5; i++) {
      bank[`Q${i}`] = { subject: 'Physics', correctAnswer: 0, optionCount: 4, difficulty: 'Medium', active: true };
    }
    for (const [id, doc] of Object.entries(bank)) db.seed(`questionBank/${id}`, doc);

    const selected: Record<string, number> = {
      Q1: 0, Q2: 0, Q3: 0, Q4: 0, Q5: 1, // 4/5 correct = 80%
    };
    const res = await handleVerifySession(
      baseReq({ questionIds: Object.keys(bank), selectedAnswers: selected }),
      AUTH,
      makeDeps(db),
    );
    // 4*15 + 5*5 + 30 = 115.
    expect(res.xpGained).toBe(115);
    expect(db.doc('users/userA/progress/data')['xpPoints']).toBe(115);
  });

  it('does NOT award the +30 bonus below 5 questions even at 100% (test 13, 21)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    // 3 questions, all correct (incl. the 3-option question, index valid).
    const res = await handleVerifySession(
      baseReq({
        subject: 'Physics',
        questionIds: ['NEET-0001', 'NEET-0002'],
        selectedAnswers: { 'NEET-0001': 2, 'NEET-0002': 0 },
      }),
      AUTH,
      makeDeps(db),
    );
    // 2*15 + 2*5 = 40; 100% accuracy but only 2 questions → no bonus.
    expect(res.xpGained).toBe(40);
  });

  it('adds +50 for a verified Daily Challenge (test 14)', async () => {
    const db = new FakeFirestore();
    const ids = seedDailySet(db);
    // 3 correct answers, 7 timed out: XP = 3*15 + 10*5 + 50 = 145.
    const selected: Record<string, number> = {};
    const timedOut: string[] = [];
    ids.forEach((id, i) => {
      if (i < 3) selected[id] = i % 4; // BIO-1→0 ✓, BIO-2→1 ✓, BIO-3→2 ✓
      else timedOut.push(id);
    });
    const res = await handleVerifySession(
      baseReq({
        sessionKind: 'dailyChallenge',
        subject: 'Daily Challenge',
        questionIds: ids,
        selectedAnswers: selected,
        timedOutQuestionIds: timedOut,
        isDailyChallenge: true,
      }),
      AUTH,
      makeDeps(db),
    );
    expect(res.xpGained).toBe(145);

    const progress = db.doc('users/userA/progress/data');
    expect(progress['lastDailyChallengeDate']).toBe(TODAY);
    expect(progress['dailyChallengeXpEarned']).toBe(145);
    expect((progress['subjectStats'] as Record<string, unknown>)['Daily Challenge']).toBeDefined();
  });

  it('awards flat +20 for diagnostic WITHOUT touching counters or streak (test 15)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    db.seed('users/userA/progress/data', {
      totalQuestions: 100, totalCorrect: 60, totalIncorrect: 40, totalUnanswered: 0,
      totalSessions: 10, xpPoints: 500, streakDays: 4, lastActiveDate: YESTERDAY,
    });
    const res = await handleVerifySession(
      baseReq({
        sessionId: 'diag-1',
        sessionKind: 'diagnostic',
        subject: 'Diagnostic — Physics',
        questionIds: ['NEET-0001'],
        selectedAnswers: { 'NEET-0001': 2 }, // would be "correct" — must NOT count
      }),
      AUTH,
      makeDeps(db),
    );
    expect(res.success).toBe(true);
    expect(res.xpGained).toBe(20);

    const progress = db.doc('users/userA/progress/data');
    expect(progress['xpPoints']).toBe(520); // +20 only
    expect(progress['totalQuestions']).toBe(100); // untouched
    expect(progress['totalCorrect']).toBe(60); // untouched
    expect(progress['totalSessions']).toBe(10); // untouched
    expect(progress['streakDays']).toBe(4); // untouched
    expect(progress['lastActiveDate']).toBe(YESTERDAY); // untouched
    expect(progress['subjectStats']).toBeUndefined(); // no subject pollution
    const rec = db.doc('users/userA/sessions/diag-1');
    expect(rec['sessionKind']).toBe('diagnostic');
    expect(rec['correct']).toBe(0);
    expect(rec['total']).toBe(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 16–17. Streak (IST)
// ─────────────────────────────────────────────────────────────────────────────
describe('streak engine (Asia/Kolkata)', () => {
  it('continues the streak when last active was yesterday (test 16)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    db.seed('users/userA/progress/data', { streakDays: 6, lastActiveDate: YESTERDAY });
    await handleVerifySession(baseReq(), AUTH, makeDeps(db));
    const progress = db.doc('users/userA/progress/data');
    expect(progress['streakDays']).toBe(7);
    expect(progress['lastActiveDate']).toBe(TODAY);
  });

  it('resets the streak to 1 after a gap (test 17)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    db.seed('users/userA/progress/data', { streakDays: 9, lastActiveDate: '2026-09-14' });
    await handleVerifySession(baseReq(), AUTH, makeDeps(db));
    expect(db.doc('users/userA/progress/data')['streakDays']).toBe(1);
  });

  it('keeps the streak unchanged for a second session the same day', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    db.seed('users/userA/progress/data', { streakDays: 5, lastActiveDate: TODAY });
    await handleVerifySession(baseReq({ sessionId: 's2' }), AUTH, makeDeps(db));
    expect(db.doc('users/userA/progress/data')['streakDays']).toBe(5);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// 18–20. Daily security + idempotency
// ─────────────────────────────────────────────────────────────────────────────
describe('Daily Challenge security (server-owned set)', () => {
  it('rejects submitted IDs that do not match today’s server-owned set (test 18)', async () => {
    const db = new FakeFirestore();
    seedDailySet(db);
    await expectHttpsError(
      handleVerifySession(
        baseReq({
          sessionKind: 'dailyChallenge',
          subject: 'Daily Challenge',
          questionIds: ['NEET-0001', 'NEET-0002'],
          selectedAnswers: { 'NEET-0001': 2, 'NEET-0002': 1 },
          isDailyChallenge: true,
        }),
        AUTH,
        makeDeps(db),
      ),
      'invalid-argument',
    );
  });

  it('rejects when today’s server-owned daily set does not exist', async () => {
    const db = new FakeFirestore(); // no daily set seeded
    seedBank(db);
    await expectHttpsError(
      handleVerifySession(
        baseReq({ sessionKind: 'dailyChallenge', subject: 'Daily Challenge', questionIds: ['X'], selectedAnswers: { X: 0 }, isDailyChallenge: true }),
        AUTH,
        makeDeps(db),
      ),
      'failed-precondition',
    );
  });

  it('prevents a second Daily Challenge on the same server day (test 19)', async () => {
    const db = new FakeFirestore();
    const ids = seedDailySet(db);
    db.seed('users/userA/progress/data', { lastDailyChallengeDate: TODAY });
    await expectHttpsError(
      handleVerifySession(
        baseReq({
          sessionId: 'daily-2',
          sessionKind: 'dailyChallenge',
          subject: 'Daily Challenge',
          questionIds: ids,
          selectedAnswers: Object.fromEntries(ids.map((id) => [id, 0])),
          isDailyChallenge: true,
        }),
        AUTH,
        makeDeps(db),
      ),
      'already-exists',
    );
  });
});

describe('idempotency', () => {
  it('does not double-award a repeated normal session submission (test 20)', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    const deps = makeDeps(db);

    const first = await handleVerifySession(baseReq(), AUTH, deps);
    expect(first.alreadyVerified).toBe(false);
    expect(first.xpGained).toBe(25);

    const second = await handleVerifySession(baseReq(), AUTH, deps);
    expect(second.success).toBe(true);
    expect(second.alreadyVerified).toBe(true);
    expect(second.xpGained).toBe(25); // previously verified result

    // Counters and XP applied exactly once.
    const progress = db.doc('users/userA/progress/data');
    expect(progress['xpPoints']).toBe(25);
    expect(progress['totalSessions']).toBe(1);
    expect(progress['totalQuestions']).toBe(2);
  });

  it('does not double-award a repeated diagnostic submission', async () => {
    const db = new FakeFirestore();
    seedBank(db);
    const deps = makeDeps(db);
    const req = baseReq({
      sessionId: 'diag-1',
      sessionKind: 'diagnostic',
      subject: 'Diagnostic — Biology',
      questionIds: ['NEET-0003'],
      selectedAnswers: { 'NEET-0003': 1 },
    });
    await handleVerifySession(req, AUTH, deps);
    const second = await handleVerifySession(req, AUTH, deps);
    expect(second.alreadyVerified).toBe(true);
    expect(second.xpGained).toBe(20);
    expect(db.doc('users/userA/progress/data')['xpPoints']).toBe(20);
  });
});
