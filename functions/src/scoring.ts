/**
 * Pure scoring logic — the trusted competitive calculation.
 *
 * Mirrors the audited client rules in
 * `lib/shared/services/user_progress_service.dart` exactly:
 *
 *   sessionXp = correct * 15 + completedCount * 5
 *   if (accuracy >= 80 && totalQuestions >= 5) sessionXp += 30
 *   dailyChallenge: sessionXp += 50
 *   diagnostic: flat +20 (no counters, no subjectStats, no streak)
 *
 * No I/O — fully unit-testable.
 */

import {
  XP_PER_CORRECT,
  XP_PER_COMPLETED,
  ACCURACY_BONUS_XP,
  ACCURACY_BONUS_MIN_ACCURACY,
  ACCURACY_BONUS_MIN_QUESTIONS,
  DAILY_CHALLENGE_BONUS_XP,
  DIAGNOSTIC_BONUS_XP,
  type SessionKind,
} from './constants';

/** A trusted answer-key entry as stored in questionBank/{questionId}. */
export interface BankQuestion {
  subject: string;
  correctAnswer: number;
  optionCount: number;
  difficulty: string;
  active: boolean;
}

/** The normalized, client-submitted request (already validated). */
export interface NormalizedRequest {
  sessionId: string;
  sessionKind: SessionKind;
  subject: string;
  questionIds: string[];
  selectedAnswers: Record<string, number>;
  timedOutQuestionIds: string[];
  timestamp: Date;
  isDailyChallenge: boolean;
}

/** Server-verified per-session results. */
export interface SessionScore {
  correct: number;
  incorrect: number;
  unanswered: number;
  totalQuestions: number;
  completedCount: number;
  /** Percent, one decimal place kept only for the >=80 gate math. */
  accuracy: number;
  sessionXp: number;
}

/**
 * Scores a (non-diagnostic) session against the trusted bank.
 *
 * Preconditions (guaranteed by the contract validator):
 *   - every ID is in exactly one state: selected or timedOut
 *   - selected indexes are integers within the question's optionCount
 */
export function scoreSession(
  request: NormalizedRequest,
  bank: Map<string, BankQuestion>,
): SessionScore {
  let correct = 0;
  let selectedCount = 0;

  for (const id of request.questionIds) {
    const selection = request.selectedAnswers[id];
    if (selection === undefined) continue; // timed out
    selectedCount++;
    if (bank.get(id)!.correctAnswer === selection) correct++;
  }

  const unanswered = request.timedOutQuestionIds.length;
  const totalQuestions = request.questionIds.length;
  const completedCount = selectedCount + unanswered;

  const accuracy =
    totalQuestions > 0 ? (correct / totalQuestions) * 100 : 0;

  let sessionXp = correct * XP_PER_CORRECT + completedCount * XP_PER_COMPLETED;
  if (
    accuracy >= ACCURACY_BONUS_MIN_ACCURACY &&
    totalQuestions >= ACCURACY_BONUS_MIN_QUESTIONS
  ) {
    sessionXp += ACCURACY_BONUS_XP;
  }
  if (request.sessionKind === 'dailyChallenge') {
    sessionXp += DAILY_CHALLENGE_BONUS_XP;
  }

  return {
    correct,
    incorrect: selectedCount - correct,
    unanswered,
    totalQuestions,
    completedCount,
    accuracy,
    sessionXp,
  };
}

/** Diagnostic XP: flat completion bonus, no per-question accounting. */
export function diagnosticXp(): number {
  return DIAGNOSTIC_BONUS_XP;
}

/**
 * IST streak engine — reproduces the client rule:
 *
 *   if lastActiveDate != today:
 *     streak = (lastActiveDate == yesterday) ? streak + 1 : 1
 *     lastActiveDate = today
 *   else: unchanged
 *
 * Opening the app never awards XP; only completed sessions move the streak.
 */
export function nextStreak(
  lastActiveDate: string,
  streakDays: number,
  todayKey: string,
  yesterdayKey: string,
): { streakDays: number; lastActiveDate: string } {
  if (lastActiveDate === todayKey) {
    return { streakDays, lastActiveDate };
  }
  const extended =
    lastActiveDate === yesterdayKey ? streakDays + 1 : 1;
  return { streakDays: extended, lastActiveDate: todayKey };
}

/**
 * Merges one session's subject-stats delta into the existing stats map,
 * keyed exactly like the client (including synthetic keys such as
 * 'Mock Test' / 'Daily Challenge' / 'Diagnostic — {subject}').
 */
export function mergeSubjectStats(
  existing: Record<
    string,
    { subject: string; totalQuestions: number; correctAnswers: number; sessionsCount: number }
  >,
  subjectKey: string,
  questionsDelta: number,
  correctDelta: number,
): Record<
  string,
  { subject: string; totalQuestions: number; correctAnswers: number; sessionsCount: number }
> {
  const current = existing[subjectKey] ?? {
    subject: subjectKey,
    totalQuestions: 0,
    correctAnswers: 0,
    sessionsCount: 0,
  };
  return {
    ...existing,
    [subjectKey]: {
      subject: subjectKey,
      totalQuestions: current.totalQuestions + questionsDelta,
      correctAnswers: current.correctAnswers + correctDelta,
      sessionsCount: current.sessionsCount + 1,
    },
  };
}
