/**
 * IST date-key tests. Asia/Kolkata is a fixed UTC+05:30 offset, so
 * wall-clock days flip at 18:30 UTC. The server clock is authoritative.
 */

import { istDateKey, istDateKeyDaysAgo, isDateKeyFormat } from '../dateKey';

describe('istDateKey', () => {
  it('derives the IST date for an instant after the 18:30 UTC flip', () => {
    // 2026-09-17T19:30:00Z = 2026-09-18 01:00 IST.
    expect(istDateKey(new Date('2026-09-17T19:30:00Z'))).toBe('2026-09-18');
  });

  it('derives the previous IST date before the 18:30 UTC flip', () => {
    // 2026-09-17T18:29:59Z = 2026-09-17 23:59:59 IST.
    expect(istDateKey(new Date('2026-09-17T18:29:59Z'))).toBe('2026-09-17');
  });

  it('handles a mid-day instant', () => {
    // 2026-09-18T04:30:00Z = 10:00 IST.
    expect(istDateKey(new Date('2026-09-18T04:30:00Z'))).toBe('2026-09-18');
  });

  it('crosses a month boundary correctly', () => {
    // 2026-09-30T19:00:00Z = 2026-10-01 00:30 IST.
    expect(istDateKey(new Date('2026-09-30T19:00:00Z'))).toBe('2026-10-01');
  });
});

describe('istDateKeyDaysAgo', () => {
  it('yields yesterday in IST', () => {
    const now = new Date('2026-09-18T10:00:00+05:30');
    expect(istDateKeyDaysAgo(now, 1)).toBe('2026-09-17');
  });

  it('yields today for daysAgo = 0', () => {
    const now = new Date('2026-09-18T10:00:00+05:30');
    expect(istDateKeyDaysAgo(now, 0)).toBe('2026-09-18');
  });

  it('crosses month and year boundaries', () => {
    const now = new Date('2026-01-01T10:00:00+05:30');
    expect(istDateKeyDaysAgo(now, 1)).toBe('2025-12-31');
  });
});

describe('isDateKeyFormat', () => {
  it('accepts well-formed date keys', () => {
    expect(isDateKeyFormat('2026-09-18')).toBe(true);
  });

  it('rejects malformed values', () => {
    expect(isDateKeyFormat('2026-9-18')).toBe(false);
    expect(isDateKeyFormat('18-09-2026')).toBe(false);
    expect(isDateKeyFormat('')).toBe(false);
    expect(isDateKeyFormat(123)).toBe(false);
    expect(isDateKeyFormat(null)).toBe(false);
  });
});
