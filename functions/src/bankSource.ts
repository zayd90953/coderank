/**
 * Production question-bank source loader + validator.
 *
 * Reads `lib/features/practice/data/questions.json` and reduces each entry
 * to the MINIMAL trusted representation:
 *
 *   questionBank/{questionId} = { subject, correctAnswer, optionCount,
 *                                 difficulty, active }
 *
 * Question text, options, and explanations are NEVER included — they are
 * client-facing content and must not live in the trusted collection.
 *
 * Accepts BOTH bank formats:
 *   * app format:    `correctAnswer` (0-based index int)
 *   * schema format: `correct_option` (letter A-F); normalized to the
 *     same 0-based index. Mixed banks are fine — validation is per-entry.
 */

import * as fs from 'fs';
import * as path from 'path';

export interface BankDoc {
  subject: string;
  correctAnswer: number;
  optionCount: number;
  difficulty: string;
  active: boolean;
}

const VALID_SUBJECTS = new Set(['Physics', 'Chemistry', 'Biology']);

/** Repo-root path of the production bank (works compiled lib/ and src/). */
export function productionBankPath(): string {
  return path.resolve(__dirname, '..', '..', 'lib', 'features', 'practice', 'data', 'questions.json');
}

/** Reads + parses the production bank file. Throws on unreadable/invalid JSON. */
export function loadProductionBankJson(): unknown {
  const file = productionBankPath();
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

export interface BankValidationResult {
  docs: Map<string, BankDoc>;
  errors: string[];
}

/**
 * Validates raw bank JSON and builds the trusted docs.
 * Never hardcodes a 4-option assumption: optionCount comes from each
 * question's actual options length, and correctAnswer must fall inside it.
 */
export function validateProductionBank(questions: unknown): BankValidationResult {
  const docs = new Map<string, BankDoc>();
  const errors: string[] = [];

  if (!Array.isArray(questions)) {
    errors.push('Bank root must be an array of questions.');
    return { docs, errors };
  }

  for (let i = 0; i < questions.length; i++) {
    const q = questions[i] as Record<string, unknown>;
    const where = `questions[${i}]${typeof q['id'] === 'string' ? ` (${q['id']})` : ''}`;

    const id = q['id'];
    if (typeof id !== 'string' || id.length === 0 || id.length > 128) {
      errors.push(`${where}: missing or invalid id`);
      continue;
    }
    if (docs.has(id)) {
      errors.push(`${where}: duplicate question id "${id}"`);
      continue;
    }

    const subject = q['subject'];
    if (typeof subject !== 'string' || !VALID_SUBJECTS.has(subject)) {
      errors.push(`${where}: invalid subject "${String(subject)}"`);
      continue;
    }

    const options = q['options'];
    if (!Array.isArray(options) || options.length < 2 || options.length > 6) {
      errors.push(`${where}: options must be an array of 2-6 entries`);
      continue;
    }

    // Accept both formats: app-format `correctAnswer` index, or schema-
    // format `correct_option` letter (A..F). Letter is normalized to the
    // 0-based index so the trusted doc shape never changes.
    let correctAnswer: number;
    const rawAnswer = q['correctAnswer'] ?? q['correct_option'];
    if (typeof rawAnswer === 'number') {
      correctAnswer = rawAnswer;
    } else if (typeof rawAnswer === 'string' && rawAnswer.length > 0) {
      const letter = rawAnswer.trim().toUpperCase().charCodeAt(0) - 65; // 'A' → 0
      correctAnswer = letter;
    } else {
      correctAnswer = -1; // falls through to the range check below
    }
    if (
      !Number.isInteger(correctAnswer) ||
      correctAnswer < 0 ||
      correctAnswer >= options.length
    ) {
      errors.push(
        `${where}: correctAnswer/correct_option must resolve to an integer in [0, ${options.length - 1}], got ${String(rawAnswer)}`,
      );
      continue;
    }

    const difficulty = q['difficulty'];
    if (typeof difficulty !== 'string' || difficulty.length === 0) {
      errors.push(`${where}: missing difficulty`);
      continue;
    }

    docs.set(id, {
      subject,
      correctAnswer,
      optionCount: options.length,
      difficulty,
      active: true,
    });
  }

  return { docs, errors };
}
