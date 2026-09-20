/**
 * `verifySession` — Firebase Callable Function v2.
 *
 * The ONLY server entry point for session submission. The client sends raw
 * answer data; this function computes every competitive value and performs
 * the atomic Firestore write. The client can NEVER write competitive fields.
 *
 * Client payload (untrusted): sessionId, sessionKind, subject, questionIds,
 * selectedAnswers, timedOutQuestionIds, timestamp, isDailyChallenge.
 *
 * Never returned/exposed: answer keys, the question bank, stack traces.
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';

import {
  QUESTION_BANK_COLLECTION,
  DAILY_SETS_COLLECTION,
  USERS_COLLECTION,
} from './constants';
import { istDateKey, istDateKeyDaysAgo } from './dateKey';
import {
  validateSessionRequest,
  requiredQuestionSubject,
  ValidationError,
  type ParsedSessionRequest,
} from './sessionContract';
import {
  scoreSession,
  nextStreak,
  mergeSubjectStats,
  diagnosticXp,
  type BankQuestion,
} from './scoring';

// ── Narrow structural interfaces (let unit tests inject fakes) ────────────

export interface DocSnapshotLike {
  exists: boolean;
  id: string;
  data(): Record<string, unknown> | undefined;
}
export interface DocRefLike {
  id: string;
  /** Full path ("users/{uid}/sessions/{id}") — used by test fakes as a key. */
  readonly path: string;
  get(): Promise<DocSnapshotLike>;
  collection(path: string): CollectionRefLike;
}
export interface CollectionRefLike {
  doc(id: string): DocRefLike;
}
export interface TxLike {
  get(ref: DocRefLike): Promise<DocSnapshotLike>;
  getAll(...refs: DocRefLike[]): Promise<DocSnapshotLike[]>;
  create(ref: DocRefLike, data: Record<string, unknown>): void;
  set(ref: DocRefLike, data: Record<string, unknown>, opts?: { merge?: boolean }): void;
}
export interface DbLike {
  collection(path: string): CollectionRefLike;
  getAll(...refs: DocRefLike[]): Promise<DocSnapshotLike[]>;
  runTransaction<T>(fn: (tx: TxLike) => Promise<T>): Promise<T>;
}

export interface VerifyDeps {
  db: DbLike;
  now: () => Date;
}

/** Response shape consumed by the Flutter `SessionSubmissionResult`. */
export interface VerifyResponse {
  success: boolean;
  alreadyVerified?: boolean;
  xpGained?: number;
  record?: Record<string, unknown>;
}

// ── Trusted bank loading ──────────────────────────────────────────────────

/** Loads the trusted bank entries for [ids] via Admin-SDK getAll (no IN-query limits). */
export async function loadBankEntries(
  db: DbLike,
  ids: string[],
): Promise<Map<string, BankQuestion>> {
  const bank = new Map<string, BankQuestion>();
  for (let i = 0; i < ids.length; i += 100) {
    const chunk = ids.slice(i, i + 100);
    const refs = chunk.map((id) =>
      db.collection(QUESTION_BANK_COLLECTION).doc(id),
    );
    const snaps = await db.getAll(...refs);
    for (const snap of snaps) {
      if (!snap.exists) continue;
      const d = snap.data();
      if (!d) continue;
      bank.set(snap.id, {
        subject: String(d['subject'] ?? ''),
        correctAnswer: Number(d['correctAnswer']),
        optionCount: Number(d['optionCount']),
        difficulty: String(d['difficulty'] ?? ''),
        active: d['active'] === true,
      });
    }
  }
  return bank;
}

// ── Response record (matches Dart SessionRecord.fromJson) ────────────────

function clientRecord(
  parsed: ParsedSessionRequest,
  data: Record<string, unknown>,
): Record<string, unknown> {
  return {
    id: parsed.sessionId,
    subject: data['subject'],
    correct: data['correct'],
    total: data['total'],
    accuracy: data['accuracy'],
    timestamp: parsed.timestamp.toISOString(),
    xpGained: data['xpGained'],
  };
}

// ── Daily-set matching (server-owned; client IDs must match exactly) ─────

function submittedIdsMatchDailySet(
  submitted: string[],
  expected: unknown,
): boolean {
  if (!Array.isArray(expected)) return false;
  if (expected.length !== submitted.length) return false;
  const expectedSet = new Set<string>(expected as string[]);
  const submittedSet = new Set<string>(submitted);
  if (expectedSet.size !== submittedSet.size) return false;
  for (const id of submittedSet) {
    if (!expectedSet.has(id)) return false;
  }
  return true;
}

// ── Core handler (dependency-injected; the callable delegates to this) ───

export async function handleVerifySession(
  rawData: unknown,
  auth: { uid: string; token: unknown } | undefined,
  deps: VerifyDeps,
): Promise<VerifyResponse> {
  const { db, now } = deps;

  // 1 ── Authentication: UID comes ONLY from the verified callable context.
  if (!auth || typeof auth.uid !== 'string' || auth.uid.length === 0) {
    throw new HttpsError('unauthenticated', 'Sign in to submit sessions.');
  }
  const uid = auth.uid;

  // 3 ── Server clock is authoritative for all date logic. Captured once
  //      and reused for both the timestamp tolerance window and IST keys.
  const nowDate = now();

  // 2 ── Contract validation (shape + per-kind internal consistency).
  let parsed: ParsedSessionRequest;
  try {
    parsed = validateSessionRequest(rawData, nowDate);
  } catch (e) {
    if (e instanceof ValidationError) {
      throw new HttpsError(e.code as 'invalid-argument', e.message);
    }
    throw e;
  }

  const todayKey = istDateKey(nowDate);
  const yesterdayKey = istDateKeyDaysAgo(nowDate, 1);

  // 4 ── Daily Challenge security: today's server-owned set must exist,
  //      be active, and match the submitted IDs exactly.
  if (parsed.sessionKind === 'dailyChallenge') {
    const setSnap = await db.collection(DAILY_SETS_COLLECTION).doc(todayKey).get();
    if (!setSnap.exists) {
      throw new HttpsError(
        'failed-precondition',
        "Today's Daily Challenge is not available yet. Please try again shortly.",
      );
    }
    const set = setSnap.data();
    if (!set || set['active'] !== true) {
      throw new HttpsError('failed-precondition', "Today's Daily Challenge is closed.");
    }
    if (!submittedIdsMatchDailySet(parsed.questionIds, set['questionIds'])) {
      throw new HttpsError(
        'invalid-argument',
        "Submitted questions do not match today's Daily Challenge.",
      );
    }
  }

  // 5 ── Trusted bank verification.
  const requiredSubject = requiredQuestionSubject(parsed);
  const bank = await loadBankEntries(db, parsed.questionIds);
  for (const id of parsed.questionIds) {
    const entry = bank.get(id);
    if (!entry) {
      throw new HttpsError('not-found', 'One or more submitted questions do not exist.');
    }
    if (!entry.active) {
      throw new HttpsError(
        'failed-precondition',
        'One or more submitted questions are no longer active.',
      );
    }
    if (requiredSubject !== null && entry.subject !== requiredSubject) {
      throw new HttpsError(
        'invalid-argument',
        'A submitted question does not belong to the session subject.',
      );
    }
  }
  for (const [id, answer] of Object.entries(parsed.selectedAnswers)) {
    if (answer >= bank.get(id)!.optionCount) {
      throw new HttpsError(
        'invalid-argument',
        'A selected answer is out of range for its question.',
      );
    }
  }

  const userRef = db.collection(USERS_COLLECTION).doc(uid);
  const sessionRef = userRef.collection('sessions').doc(parsed.sessionId);
  // Doc id 'data' matches the Flutter FirestorePaths.progress(uid) layout.
  const progressRef = userRef.collection('progress').doc('data');

  // 6 ── Diagnostic: special accounting (audited client semantics).
  //      +20 flat XP ONLY — no counters, no subjectStats, no streak,
  //      no daily-challenge state. sessionId doc = idempotency record.
  if (parsed.sessionKind === 'diagnostic') {
    const xp = diagnosticXp();
    return db.runTransaction(async (tx) => {
      const existing = await tx.get(sessionRef);
      if (existing.exists) {
        const prev = existing.data();
        return {
          success: true,
          alreadyVerified: true,
          xpGained: typeof prev?.['xpGained'] === 'number' ? prev['xpGained'] : xp,
          record: prev ? clientRecord(parsed, prev) : undefined,
        } as VerifyResponse;
      }
      const record: Record<string, unknown> = {
        subject: parsed.subject,
        correct: 0,
        total: 0,
        accuracy: 0,
        timestamp: Timestamp.fromDate(parsed.timestamp),
        xpGained: xp,
        isDailyChallenge: false,
        sessionKind: 'diagnostic',
        createdAt: FieldValue.serverTimestamp(),
      };
      tx.create(sessionRef, record);
      tx.set(
        progressRef,
        { xpPoints: FieldValue.increment(xp), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return {
        success: true,
        alreadyVerified: false,
        xpGained: xp,
        record: clientRecord(parsed, record),
      } as VerifyResponse;
    });
  }

  // 7 ── Normal competitive session: score server-side.
  const score = scoreSession(parsed, bank);

  // 8 ── Atomic write: idempotency + streak + counters in one transaction.
  return db.runTransaction(async (tx) => {
    const [sessionSnap, progressSnap] = await tx.getAll(sessionRef, progressRef);

    // Idempotency: same sessionId never awards twice.
    if (sessionSnap.exists) {
      const prev = sessionSnap.data();
      return {
        success: true,
        alreadyVerified: true,
        xpGained: typeof prev?.['xpGained'] === 'number' ? prev['xpGained'] : score.sessionXp,
        record: prev ? clientRecord(parsed, prev) : undefined,
      } as VerifyResponse;
    }

    const progress = progressSnap.exists ? progressSnap.data() ?? {} : {};

    // Daily one-per-day enforcement (server date).
    if (parsed.sessionKind === 'dailyChallenge') {
      const lastDaily =
        typeof progress['lastDailyChallengeDate'] === 'string'
          ? progress['lastDailyChallengeDate']
          : '';
      if (lastDaily === todayKey) {
        throw new HttpsError(
          'already-exists',
          'Daily Challenge has already been completed today.',
        );
      }
    }

    // Streak engine (IST dates; diagnostic never reaches here).
    const lastActive =
      typeof progress['lastActiveDate'] === 'string' ? progress['lastActiveDate'] : '';
    const currentStreak =
      typeof progress['streakDays'] === 'number' ? progress['streakDays'] : 0;
    const streak = nextStreak(lastActive, currentStreak, todayKey, yesterdayKey);

    // Subject stats — client keying preserved ('Mock Test', 'Daily Challenge').
    const statsRaw = progress['subjectStats'];
    const stats: Record<
      string,
      { subject: string; totalQuestions: number; correctAnswers: number; sessionsCount: number }
    > = {};
    if (statsRaw && typeof statsRaw === 'object') {
      for (const [key, value] of Object.entries(statsRaw as Record<string, unknown>)) {
        if (value && typeof value === 'object') {
          const v = value as Record<string, unknown>;
          stats[key] = {
            subject: String(v['subject'] ?? key),
            totalQuestions: Number(v['totalQuestions'] ?? 0),
            correctAnswers: Number(v['correctAnswers'] ?? 0),
            sessionsCount: Number(v['sessionsCount'] ?? 0),
          };
        }
      }
    }
    const newStats = mergeSubjectStats(
      stats,
      parsed.subject,
      score.completedCount,
      score.correct,
    );

    // Immutable session record.
    const record: Record<string, unknown> = {
      subject: parsed.subject,
      correct: score.correct,
      total: score.totalQuestions,
      accuracy: Math.round(score.accuracy * 100) / 100,
      timestamp: Timestamp.fromDate(parsed.timestamp),
      xpGained: score.sessionXp,
      isDailyChallenge: parsed.isDailyChallenge,
      sessionKind: parsed.sessionKind,
      createdAt: FieldValue.serverTimestamp(),
    };
    tx.create(sessionRef, record);

    // Server-authoritative progress update — the ONLY writer of these fields.
    const progressUpdate: Record<string, unknown> = {
      totalQuestions: FieldValue.increment(score.completedCount),
      totalCorrect: FieldValue.increment(score.correct),
      totalIncorrect: FieldValue.increment(score.incorrect),
      totalUnanswered: FieldValue.increment(score.unanswered),
      totalSessions: FieldValue.increment(1),
      xpPoints: FieldValue.increment(score.sessionXp),
      streakDays: streak.streakDays,
      lastActiveDate: streak.lastActiveDate,
      subjectStats: newStats,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (parsed.sessionKind === 'dailyChallenge') {
      progressUpdate['lastDailyChallengeDate'] = todayKey;
      progressUpdate['dailyChallengeXpEarned'] = FieldValue.increment(score.sessionXp);
    }
    tx.set(progressRef, progressUpdate, { merge: true });

    return {
      success: true,
      alreadyVerified: false,
      xpGained: score.sessionXp,
      record: clientRecord(parsed, record),
    } as VerifyResponse;
  });
}

// ── Callable wrapper ──────────────────────────────────────────────────────

/** Lazily initializes the Admin app (import-time side effects avoided for tests). */
function ensureAdminApp(): void {
  if (getApps().length === 0) {
    initializeApp();
  }
}

/**
 * Callable: `verifySession` (us-central1 — matches the Flutter client's
 * default FirebaseFunctions.instance.httpsCallable('verifySession')).
 */
export const verifySession = onCall(
  {
    region: 'us-central1',
    // Answer-key collections are Admin-only; App Check can be enabled later.
    enforceAppCheck: false,
  },
  async (request) => {
    ensureAdminApp();
    return handleVerifySession(request.data, request.auth, {
      db: getFirestore() as unknown as DbLike,
      now: () => new Date(),
    });
  },
);
