/**
 * Asia/Kolkata (IST, fixed UTC+05:30 — India has no DST) date helpers.
 *
 * The server clock is the ONLY source of "today": the client timestamp is
 * metadata and is never used to derive the current day.
 */

import { IST_OFFSET_MINUTES } from './constants';

/** IST wall-clock calendar fields for an instant. */
export function istCalendar(now: Date): {
  year: number;
  month: number;
  day: number;
} {
  const shifted = new Date(now.getTime() + IST_OFFSET_MINUTES * 60 * 1000);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
  };
}

/** Pads a number to two digits ("2026-09-18"). */
function pad2(n: number): string {
  return String(n).padStart(2, '0');
}

/**
 * The authoritative dateKey ("YYYY-MM-DD", Asia/Kolkata) for an instant.
 * This is the format of `lastActiveDate`, `lastDailyChallengeDate`, and the
 * `dailyChallengeSets` document IDs.
 */
export function istDateKey(now: Date = new Date()): string {
  const { year, month, day } = istCalendar(now);
  return `${year}-${pad2(month)}-${pad2(day)}`;
}

/** dateKey for exactly `daysAgo` days before the IST day of `now`. */
export function istDateKeyDaysAgo(now: Date, daysAgo: number): string {
  const { year, month, day } = istCalendar(now);
  // Construct the IST day as a UTC date, then subtract whole days.
  const utcDay = Date.UTC(year, month - 1, day) - daysAgo * 86_400_000;
  const d = new Date(utcDay);
  return `${d.getUTCFullYear()}-${pad2(d.getUTCMonth() + 1)}-${pad2(d.getUTCDate())}`;
}

/** True when [value] is a well-formed "YYYY-MM-DD" string. */
export function isDateKeyFormat(value: unknown): value is string {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value);
}
