/**
 * Daily-set generator tests. Uses a fixed test secret and the REAL
 * production bank (read-only) to verify shape, determinism, and uniqueness.
 */

import { loadProductionBankJson, validateProductionBank } from '../bankSource';
import { generateDailySetForDate } from '../generateDailySet';

const SECRET = 'test-secret-for-unit-tests';
const DATE = '2026-09-21';

function bank(): ReturnType<typeof validateProductionBank>['docs'] {
  return validateProductionBank(loadProductionBankJson()).docs;
}

describe('generateDailySetForDate', () => {
  it('produces exactly 10 distinct IDs: 4 Biology + 3 Physics + 3 Chemistry', () => {
    const set = generateDailySetForDate(bank(), DATE, SECRET);
    expect(set.questionIds).toHaveLength(10);
    expect(new Set(set.questionIds).size).toBe(10); // no duplicates

    const bySubject = new Map<string, number>();
    for (const id of set.questionIds) {
      const subject = bank().get(id)!.subject;
      bySubject.set(subject, (bySubject.get(subject) ?? 0) + 1);
    }
    expect(bySubject.get('Biology')).toBe(4);
    expect(bySubject.get('Physics')).toBe(3);
    expect(bySubject.get('Chemistry')).toBe(3);
  });

  it('draws only from the high-yield pool (difficulty != Easy)', () => {
    const docs = bank();
    const set = generateDailySetForDate(docs, DATE, SECRET);
    for (const id of set.questionIds) {
      expect(docs.get(id)!.difficulty).not.toBe('Easy');
    }
  });

  it('is stable for a given (dateKey, secret): repeated runs are identical', () => {
    const a = generateDailySetForDate(bank(), DATE, SECRET);
    const b = generateDailySetForDate(bank(), DATE, SECRET);
    expect(a.questionIds).toEqual(b.questionIds);
    expect(a.dateKey).toBe(DATE);
    expect(a.active).toBe(true);
  });

  it('can be generated ahead of time for future dates', () => {
    const future = generateDailySetForDate(bank(), '2026-12-25', SECRET);
    expect(future.dateKey).toBe('2026-12-25');
    expect(future.questionIds).toHaveLength(10);
  });

  it('produces different sets for different dates', () => {
    const a = generateDailySetForDate(bank(), '2026-09-21', SECRET);
    const b = generateDailySetForDate(bank(), '2026-09-22', SECRET);
    expect(a.questionIds).not.toEqual(b.questionIds);
  });

  it('rejects a malformed dateKey', () => {
    expect(() => generateDailySetForDate(bank(), '09-21-2026', SECRET)).toThrow(/YYYY-MM-DD/);
  });

  it('documents the doc shape: dateKey, questionIds, generatedAt, active', () => {
    const set = generateDailySetForDate(bank(), DATE, SECRET);
    expect(Object.keys(set).sort()).toEqual(
      ['active', 'dateKey', 'generatedAt', 'questionIds'].sort(),
    );
  });
});
