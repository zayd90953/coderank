/**
 * questionBank validation tests against the REAL production bank file.
 * Read-only — nothing is imported into Firestore by tests.
 *
 * Assertions are derived from the bank itself rather than pinned to a
 * specific question count, so the bank can be replaced (e.g. the schema-
 * format 4,982-question bank) without touching this file.
 */

import { loadProductionBankJson, validateProductionBank } from '../bankSource';

describe('production bank validation', () => {
  const { docs, errors } = validateProductionBank(loadProductionBankJson());

  it('validates every production question with zero errors', () => {
    expect(errors).toEqual([]);
    expect(docs.size).toBeGreaterThan(0);
  });

  it('reduces each question to the minimal trusted doc shape', () => {
    const sample = docs.values().next().value!;
    expect(Object.keys(sample).sort()).toEqual(
      ['active', 'correctAnswer', 'difficulty', 'optionCount', 'subject'].sort(),
    );
    // Client-facing content must never appear in the trusted doc.
    expect(sample).not.toHaveProperty('question');
    expect(sample).not.toHaveProperty('options');
    expect(sample).not.toHaveProperty('explanation');
  });

  it('preserves subject and difficulty, marks everything active', () => {
    const subjectCounts = new Map<string, number>();
    for (const doc of docs.values()) {
      subjectCounts.set(doc.subject, (subjectCounts.get(doc.subject) ?? 0) + 1);
      expect(doc.active).toBe(true);
      expect(['Medium', 'Hard', 'Easy']).toContain(doc.difficulty);
      expect(Number.isInteger(doc.correctAnswer)).toBe(true);
      expect(doc.correctAnswer).toBeGreaterThanOrEqual(0);
      expect(doc.correctAnswer).toBeLessThan(doc.optionCount);
    }
    // The bank must cover exactly the three NEET subjects.
    expect([...subjectCounts.keys()].sort()).toEqual(['Biology', 'Chemistry', 'Physics']);
  });

  it('never hardcodes a 4-option assumption (optionCount follows the data)', () => {
    const optionCounts = new Set<number>();
    for (const doc of docs.values()) {
      optionCounts.add(doc.optionCount);
      expect(doc.optionCount).toBeGreaterThanOrEqual(2);
      expect(doc.optionCount).toBeLessThanOrEqual(6);
    }
    // Sanity: at least one 4-option question exists in any bank version.
    expect(optionCounts.has(4)).toBe(true);
  });
});

describe('schema-format (correct_option letter) normalization', () => {
  it('maps A-D letters to 0-based indices and rejects out-of-range letters', () => {
    const { docs, errors } = validateProductionBank([
      {
        id: 'SCHEMA-A',
        subject: 'Physics',
        difficulty: 'Medium',
        options: ['a', 'b', 'c', 'd'],
        correct_option: 'A',
      },
      {
        id: 'SCHEMA-D',
        subject: 'Biology',
        difficulty: 'Hard',
        options: ['a', 'b', 'c', 'd'],
        correct_option: 'd', // lowercase tolerated
      },
      {
        id: 'SCHEMA-BAD',
        subject: 'Chemistry',
        difficulty: 'Medium',
        options: ['a', 'b', 'c', 'd'],
        correct_option: 'E', // out of range for 4 options
      },
    ]);

    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('SCHEMA-BAD');
    expect(docs.get('SCHEMA-A')).toMatchObject({ correctAnswer: 0, optionCount: 4 });
    expect(docs.get('SCHEMA-D')).toMatchObject({ correctAnswer: 3, optionCount: 4 });
  });

  it('still accepts app-format correctAnswer integers (mixed banks are fine)', () => {
    const { docs, errors } = validateProductionBank([
      {
        id: 'APP-1',
        subject: 'Physics',
        difficulty: 'Easy',
        options: ['a', 'b', 'c'],
        correctAnswer: 2,
      },
    ]);
    expect(errors).toEqual([]);
    expect(docs.get('APP-1')).toMatchObject({ correctAnswer: 2, optionCount: 3 });
  });
});
