/**
 * Shared backend constants — single source of truth for the trusted
 * competitive-scoring rules. Values mirror the audited client logic in
 * `lib/shared/services/user_progress_service.dart`.
 */

// ── Firestore paths ────────────────────────────────────────────────────────
export const QUESTION_BANK_COLLECTION = 'questionBank';
export const DAILY_SETS_COLLECTION = 'dailyChallengeSets';
export const USERS_COLLECTION = 'users';

// ── Session kinds (final contract) ────────────────────────────────────────
export const SESSION_KINDS = [
  'practice',
  'dailyChallenge',
  'mockFull',
  'mockQuick',
  'diagnostic',
] as const;
export type SessionKind = (typeof SESSION_KINDS)[number];

// ── Timezone policy ───────────────────────────────────────────────────────
/** Authoritative timezone for streak dates and daily enforcement. */
export const TIMEZONE = 'Asia/Kolkata';
/** IST has a fixed offset (India has no DST). */
export const IST_OFFSET_MINUTES = 330;

// ── Client timestamp tolerance (metadata only) ────────────────────────────
/**
 * The client timestamp is metadata and is NEVER used to derive "today".
 * A submission is rejected when the client clock is badly out of sync:
 * more than 10 minutes in the future, or older than 24 hours.
 */
export const TIMESTAMP_MAX_FUTURE_MS = 10 * 60 * 1000; // 10 minutes
export const TIMESTAMP_MAX_AGE_MS = 24 * 60 * 60 * 1000; // 24 hours

// ── Scoring rules (audited) ───────────────────────────────────────────────
export const XP_PER_CORRECT = 15;
export const XP_PER_COMPLETED = 5;
export const ACCURACY_BONUS_XP = 30;
export const ACCURACY_BONUS_MIN_ACCURACY = 80;
export const ACCURACY_BONUS_MIN_QUESTIONS = 5;

/** Daily Challenge completion bonus (on top of the base formula). */
export const DAILY_CHALLENGE_BONUS_XP = 50;
/** Diagnostic flat completion XP — diagnostic awards ONLY this. */
export const DIAGNOSTIC_BONUS_XP = 20;

/** Exact daily set shape: 4 Bio + 3 Phy + 3 Chem, difficulty != Easy. */
export const DAILY_SET_TOTAL = 10;
export const DAILY_SET_BIO = 4;
export const DAILY_SET_PHY = 3;
export const DAILY_SET_CHEM = 3;
export const DAILY_HIGH_YIELD_DIFFICULTIES = ['Medium', 'Hard'];

// ── Sensible per-kind question counts (audit: 2,229-question bank) ────────
// Mock pool sizes: 643 Physics / 588 Chemistry / 998 Biology.
export const MAX_QUESTIONS_PER_SESSION: Record<SessionKind, number> = {
  practice: 200,
  dailyChallenge: 10,
  mockFull: 180,
  mockQuick: 45,
  diagnostic: 24,
};
export const DAILY_SET_DATE_KEY_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
