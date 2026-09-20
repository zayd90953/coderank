/**
 * CodeRank trusted backend — Firebase Functions v2 (Node.js 22, TypeScript).
 *
 * This module re-exports the shared contract constants and exposes the
 * `verifySession` callable. Verification logic lives in verifySession.ts;
 * scoring/validation rules live in constants.ts / scoring.ts /
 * sessionContract.ts (all unit-tested under src/__tests__/).
 */

// ── Shared contract constants (single source of truth: constants.ts) ─────
export {
  QUESTION_BANK_COLLECTION,
  DAILY_SETS_COLLECTION,
  USERS_COLLECTION,
  SESSION_KINDS,
  TIMEZONE,
  IST_OFFSET_MINUTES,
  TIMESTAMP_MAX_FUTURE_MS,
  TIMESTAMP_MAX_AGE_MS,
  XP_PER_CORRECT,
  XP_PER_COMPLETED,
  ACCURACY_BONUS_XP,
  ACCURACY_BONUS_MIN_ACCURACY,
  ACCURACY_BONUS_MIN_QUESTIONS,
  DAILY_CHALLENGE_BONUS_XP,
  DIAGNOSTIC_BONUS_XP,
  DAILY_SET_TOTAL,
  DAILY_SET_BIO,
  DAILY_SET_PHY,
  DAILY_SET_CHEM,
  DAILY_HIGH_YIELD_DIFFICULTIES,
} from './constants';
export type { SessionKind } from './constants';

// ── Deployed shapes (approved architecture) ───────────────────────────────
// Trusted answer key:  questionBank/{questionId}   (Admin SDK only — never client-readable)
// Daily sets:          dailyChallengeSets/{dateKey} ("YYYY-MM-DD", Asia/Kolkata)
// Progress:            users/{uid}/progress/data
// Sessions:            users/{uid}/sessions/{sessionId}  (immutable; idempotency record)

/**
 * Path templates kept for documentation/tooling parity with the Flutter
 * FirestorePaths class.
 */
export const FIRESTORE_PATHS = {
  questionBank: 'questionBank',
  dailyChallengeSets: 'dailyChallengeSets',
  userProgress: 'users/{uid}/progress',
  userSessions: 'users/{uid}/sessions/{sessionId}',
} as const;

/** The callable function name invoked by the Flutter client. */
export const VERIFY_SESSION_FUNCTION_NAME = 'verifySession';

/**
 * Server-authoritative progress fields — documented mirror of
 * `kServerAuthoritativeProgressFields` in
 * lib/shared/services/firestore_sync_service.dart. The client never writes
 * these; verifySession is the only writer.
 */
export const SERVER_AUTHORITATIVE_PROGRESS_FIELDS = [
  'xpPoints',
  'totalQuestions',
  'totalCorrect',
  'totalIncorrect',
  'totalUnanswered',
  'totalSessions',
  'streakDays',
  'lastActiveDate',
  'subjectStats',
  'lastDailyChallengeDate',
  'dailyChallengeXpEarned',
] as const;

// ── The callable ──────────────────────────────────────────────────────────
export { verifySession } from './verifySession';
