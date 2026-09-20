/**
 * Pure session-request contract validation.
 *
 * Validates ONLY the shape and internal consistency of the untrusted client
 * payload. Question-ID existence/activeness checks live in verifySession
 * (they need the trusted bank). Throws {@link ValidationError} with a
 * Firebase callable error code; the callable layer maps it to HttpsError.
 */

import {
  SESSION_KINDS,
  MAX_QUESTIONS_PER_SESSION,
  TIMESTAMP_MAX_FUTURE_MS,
  TIMESTAMP_MAX_AGE_MS,
  type SessionKind,
} from './constants';

/** Error carrying a Firebase callable error code. */
export class ValidationError extends Error {
  readonly code: string;
  constructor(code: string, message: string) {
    super(message);
    this.name = 'ValidationError';
    this.code = code;
  }
}

const SUBJECT_LITERALS = ['Physics', 'Chemistry', 'Biology'] as const;
export const MOCK_TEST_SUBJECT = 'Mock Test';
export const DAILY_CHALLENGE_SUBJECT = 'Daily Challenge';

const SESSION_ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;

/** String-literal subjects a diagnostic must end with ("Diagnostic — Physics"). */
const DIAGNOSTIC_SUBJECT_PATTERN = /^Diagnostic — (Physics|Chemistry|Biology)$/;

export interface ParsedSessionRequest {
  sessionId: string;
  sessionKind: SessionKind;
  subject: string;
  questionIds: string[];
  selectedAnswers: Record<string, number>;
  timedOutQuestionIds: string[];
  timestamp: Date;
  isDailyChallenge: boolean;
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

/**
 * Validates the raw callable payload. `data` is the unwrapped `data` field
 * of the callable request (Firebase Functions v2 envelope). `now` is the
 * SERVER clock (injected by the handler) — never the client timestamp —
 * and is used only for the tolerance window on the metadata timestamp.
 */
export function validateSessionRequest(
  data: unknown,
  now: Date = new Date(),
): ParsedSessionRequest {
  if (!isPlainObject(data)) {
    throw new ValidationError('invalid-argument', 'Request body must be an object.');
  }

  // ── sessionId ────────────────────────────────────────────────────────
  const sessionId = data['sessionId'];
  if (typeof sessionId !== 'string' || !SESSION_ID_PATTERN.test(sessionId)) {
    throw new ValidationError(
      'invalid-argument',
      'sessionId must be 1-128 characters of [A-Za-z0-9_-].',
    );
  }

  // ── sessionKind ──────────────────────────────────────────────────────
  const sessionKind = data['sessionKind'];
  if (
    typeof sessionKind !== 'string' ||
    !(SESSION_KINDS as readonly string[]).includes(sessionKind)
  ) {
    throw new ValidationError(
      'invalid-argument',
      'sessionKind must be one of: ' + SESSION_KINDS.join(', ') + '.',
    );
  }
  const kind = sessionKind as SessionKind;

  // ── subject ──────────────────────────────────────────────────────────
  const subject = data['subject'];
  if (typeof subject !== 'string' || subject.length < 1 || subject.length > 64) {
    throw new ValidationError('invalid-argument', 'subject must be a 1-64 character string.');
  }

  // ── questionIds ──────────────────────────────────────────────────────
  const questionIdsRaw = data['questionIds'];
  if (!Array.isArray(questionIdsRaw) || questionIdsRaw.length === 0) {
    throw new ValidationError('invalid-argument', 'questionIds must be a non-empty array.');
  }
  if (questionIdsRaw.length > MAX_QUESTIONS_PER_SESSION[kind]) {
    throw new ValidationError(
      'invalid-argument',
      'questionIds exceeds the maximum of ' + MAX_QUESTIONS_PER_SESSION[kind] + ' for ' + kind + '.',
    );
  }
  const questionIds: string[] = [];
  for (const id of questionIdsRaw) {
    if (typeof id !== 'string' || id.length === 0 || id.length > 128) {
      throw new ValidationError('invalid-argument', 'Each questionId must be a string.');
    }
    questionIds.push(id);
  }
  const idSet = new Set(questionIds);
  if (idSet.size !== questionIds.length) {
    throw new ValidationError('invalid-argument', 'Duplicate question IDs are not allowed.');
  }

  // ── selectedAnswers ──────────────────────────────────────────────────
  const selectedRaw = data['selectedAnswers'];
  if (!isPlainObject(selectedRaw)) {
    throw new ValidationError('invalid-argument', 'selectedAnswers must be an object.');
  }
  const selectedAnswers: Record<string, number> = {};
  for (const [id, answer] of Object.entries(selectedRaw)) {
    if (!idSet.has(id)) {
      throw new ValidationError('invalid-argument', 'selectedAnswers contains an unknown question ID.');
    }
    if (typeof answer !== 'number' || !Number.isInteger(answer) || answer < 0) {
      throw new ValidationError('invalid-argument', 'Selected answers must be non-negative integers.');
    }
    selectedAnswers[id] = answer;
  }

  // ── timedOutQuestionIds ──────────────────────────────────────────────
  const timedOutRaw = data['timedOutQuestionIds'];
  if (!Array.isArray(timedOutRaw)) {
    throw new ValidationError('invalid-argument', 'timedOutQuestionIds must be an array.');
  }
  const timedOutQuestionIds: string[] = [];
  for (const id of timedOutRaw) {
    if (typeof id !== 'string' || !idSet.has(id)) {
      throw new ValidationError('invalid-argument', 'timedOutQuestionIds contains an unknown question ID.');
    }
    timedOutQuestionIds.push(id);
  }
  if (new Set(timedOutQuestionIds).size !== timedOutQuestionIds.length) {
    throw new ValidationError('invalid-argument', 'Duplicate timed-out question IDs are not allowed.');
  }

  // ── every question in exactly one state: selected OR timedOut ────────
  const selectedKeys = new Set(Object.keys(selectedAnswers));
  for (const id of timedOutQuestionIds) {
    if (selectedKeys.has(id)) {
      throw new ValidationError(
        'invalid-argument',
        'A question cannot be both selected and timed out.',
      );
    }
  }
  const missing = questionIds.filter(
    (id) => !selectedKeys.has(id) && !timedOutQuestionIds.includes(id),
  );
  if (missing.length > 0) {
    throw new ValidationError(
      'invalid-argument',
      'Every submitted question must be either selected or timed out.',
    );
  }

  // ── timestamp (metadata only; server date is authoritative) ──────────
  const timestampRaw = data['timestamp'];
  if (typeof timestampRaw !== 'string') {
    throw new ValidationError('invalid-argument', 'timestamp must be an ISO 8601 string.');
  }
  const timestamp = new Date(timestampRaw);
  if (Number.isNaN(timestamp.getTime())) {
    throw new ValidationError('invalid-argument', 'timestamp is not a valid ISO 8601 date.');
  }
  const nowMs = now.getTime();
  if (timestamp.getTime() > nowMs + TIMESTAMP_MAX_FUTURE_MS) {
    throw new ValidationError('invalid-argument', 'timestamp is too far in the future.');
  }
  if (timestamp.getTime() < nowMs - TIMESTAMP_MAX_AGE_MS) {
    throw new ValidationError('invalid-argument', 'timestamp is too old.');
  }

  // ── isDailyChallenge + per-kind consistency ──────────────────────────
  const isDailyChallenge = data['isDailyChallenge'];
  if (typeof isDailyChallenge !== 'boolean') {
    throw new ValidationError('invalid-argument', 'isDailyChallenge must be a boolean.');
  }
  if (kind === 'dailyChallenge' && !isDailyChallenge) {
    throw new ValidationError(
      'invalid-argument',
      'dailyChallenge sessions must have isDailyChallenge = true.',
    );
  }
  if (kind !== 'dailyChallenge' && isDailyChallenge) {
    throw new ValidationError(
      'invalid-argument',
      'Only dailyChallenge sessions may have isDailyChallenge = true.',
    );
  }

  // Per-kind subject rules (mirror audited client keying):
  if (kind === 'practice' && !(SUBJECT_LITERALS as readonly string[]).includes(subject)) {
    throw new ValidationError(
      'invalid-argument',
      'practice subject must be Physics, Chemistry, or Biology.',
    );
  }
  if ((kind === 'mockFull' || kind === 'mockQuick') && subject !== MOCK_TEST_SUBJECT) {
    throw new ValidationError('invalid-argument', 'Mock sessions must use subject "Mock Test".');
  }
  if (kind === 'dailyChallenge' && subject !== DAILY_CHALLENGE_SUBJECT) {
    throw new ValidationError(
      'invalid-argument',
      'Daily Challenge sessions must use subject "Daily Challenge".',
    );
  }
  if (kind === 'diagnostic' && !DIAGNOSTIC_SUBJECT_PATTERN.test(subject)) {
    throw new ValidationError(
      'invalid-argument',
      'Diagnostic subject must be "Diagnostic — Physics", "Diagnostic — Chemistry", or "Diagnostic — Biology".',
    );
  }

  return {
    sessionId,
    sessionKind: kind,
    subject,
    questionIds,
    selectedAnswers,
    timedOutQuestionIds,
    timestamp,
    isDailyChallenge,
  };
}

/**
 * The subject a question must have in the trusted bank for this session
 * kind, or null when per-question subject matching does not apply
 * (mock sessions mix all three subjects; daily sets span all three).
 */
export function requiredQuestionSubject(request: ParsedSessionRequest): string | null {
  if (request.sessionKind === 'practice') return request.subject;
  if (request.sessionKind === 'diagnostic') {
    return DIAGNOSTIC_SUBJECT_PATTERN.exec(request.subject)![1];
  }
  return null;
}
