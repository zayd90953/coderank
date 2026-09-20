/**
 * dailyChallengeSets generator (operator tool — never called by the app).
 *
 * The client's Dart PRNG cannot be reproduced in Node, so the daily set is
 * SERVER-OWNED and generated with a deterministic-but-unpredictable method:
 *
 *   HMAC-SHA256(key = secret, message = "daily/{dateKey}/{subject}/{slot}")
 *   → integer index into that subject's high-yield bucket (forward walk on
 *     collision, so the 10 picks are always distinct).
 *
 * Stability: for a given (dateKey, secret) the output is identical every
 * run — the set can be generated days ahead of time.
 *
 * Usage (from functions/):
 *   npm run generate:daily                       → today (IST), dry-run
 *   npm run generate:daily -- --date 2026-09-25  → a future date, dry-run
 *   npm run generate:daily -- --write            → upsert to Firestore
 *   DAILY_SET_SECRET=<hex> …                     → stable generation key
 *
 * Requires ADC (firebase login / service account) only for --write.
 */

import * as crypto from 'crypto';

import {
  DAILY_SETS_COLLECTION,
  DAILY_SET_BIO,
  DAILY_SET_CHEM,
  DAILY_SET_PHY,
  DAILY_HIGH_YIELD_DIFFICULTIES,
} from './constants';
import { isDateKeyFormat } from './dateKey';
import type { BankDoc } from './bankSource';

const SUBJECT_PLAN: Array<{ subject: string; count: number }> = [
  { subject: 'Biology', count: DAILY_SET_BIO },
  { subject: 'Physics', count: DAILY_SET_PHY },
  { subject: 'Chemistry', count: DAILY_SET_CHEM },
];

export interface DailySetDoc {
  dateKey: string;
  questionIds: string[];
  generatedAt: string;
  active: boolean;
}

/** HMAC index for one slot — deterministic for (secret, dateKey, subject, slot). */
function slotIndex(
  secret: string,
  dateKey: string,
  subject: string,
  slot: number,
  bucketSize: number,
): number {
  const digest = crypto
    .createHmac('sha256', secret)
    .update(`daily/${dateKey}/${subject}/${slot}`)
    .digest();
  return digest.readUInt32BE(0) % bucketSize;
}

/**
 * Picks the daily set from validated bank docs.
 * Pure + deterministic: same inputs → same 10 IDs, no duplicates.
 */
export function generateDailySetForDate(
  docs: Map<string, BankDoc>,
  dateKey: string,
  secret: string,
): DailySetDoc {
  if (!isDateKeyFormat(dateKey)) {
    throw new Error(`dateKey must be YYYY-MM-DD, got "${dateKey}"`);
  }

  // High-yield pool only (difficulty != Easy).
  const buckets = new Map<string, string[]>();
  for (const subject of ['Biology', 'Physics', 'Chemistry']) {
    buckets.set(subject, []);
  }
  for (const [id, doc] of docs) {
    if (!doc.active) continue;
    if (!DAILY_HIGH_YIELD_DIFFICULTIES.includes(doc.difficulty)) continue;
    const bucket = buckets.get(doc.subject);
    if (bucket) bucket.push(id);
  }
  for (const bucket of buckets.values()) bucket.sort(); // stable base order

  const picked = new Set<string>();
  const questionIds: string[] = [];
  for (const { subject, count } of SUBJECT_PLAN) {
    const bucket = buckets.get(subject)!;
    if (bucket.length < count) {
      throw new Error(
        `High-yield ${subject} pool has only ${bucket.length} questions (needs ${count}).`,
      );
    }
    for (let slot = 0; slot < count; slot++) {
      let idx = slotIndex(secret, dateKey, subject, slot, bucket.length);
      // Forward walk until an unpicked ID is found (guarantees distinctness).
      for (let step = 0; step < bucket.length; step++) {
        const candidate = bucket[(idx + step) % bucket.length];
        if (!picked.has(candidate)) {
          picked.add(candidate);
          questionIds.push(candidate);
          break;
        }
      }
    }
  }

  if (questionIds.length !== DAILY_SET_BIO + DAILY_SET_PHY + DAILY_SET_CHEM) {
    throw new Error('Daily set generation failed to fill all 10 slots.');
  }

  return {
    dateKey,
    questionIds: questionIds.sort(), // canonical order; matching is set-based
    generatedAt: new Date().toISOString(),
    active: true,
  };
}

async function main(): Promise<void> {
  const argv = process.argv.slice(2);
  const write = argv.includes('--write');
  const dateArgIdx = argv.indexOf('--date');
  const { istDateKey } = await import('./dateKey');
  const dateKey = dateArgIdx !== -1 ? argv[dateArgIdx + 1] : istDateKey();

  const { loadProductionBankJson, validateProductionBank } = await import('./bankSource');
  const { docs, errors } = validateProductionBank(loadProductionBankJson());
  if (errors.length > 0) {
    console.error(`ABORT: ${errors.length} bank validation errors (run import:bank dry-run).`);
    process.exitCode = 1;
    if (!write) return;
    return;
  }

  const secret = process.env['DAILY_SET_SECRET'] ?? '';
  if (!secret) {
    console.error('ABORT: set DAILY_SET_SECRET (stable secret used for deterministic picks).');
    process.exitCode = 1;
    return;
  }

  const set = generateDailySetForDate(docs, dateKey, secret);

  console.log('── dailyChallengeSets generator ─────────────────────');
  console.log(`mode   : ${write ? 'WRITE' : 'DRY-RUN (no data modified)'}`);
  console.log(`dateKey: ${set.dateKey} (Asia/Kolkata)`);
  const bySubject = new Map<string, number>();
  for (const id of set.questionIds) {
    const subject = docs.get(id)!.subject;
    bySubject.set(subject, (bySubject.get(subject) ?? 0) + 1);
  }
  console.log('shape  :', Object.fromEntries(bySubject));
  console.log('ids    :', set.questionIds.join(', '));

  // Stability check: regenerate and compare.
  const again = generateDailySetForDate(docs, dateKey, secret);
  console.log('stable :', JSON.stringify(again.questionIds) === JSON.stringify(set.questionIds));

  if (!write) {
    console.log('dry-run complete — re-run with --write to upsert.');
    return;
  }

  const { initializeApp, getApps } = await import('firebase-admin/app');
  const { getFirestore, FieldValue } = await import('firebase-admin/firestore');
  if (getApps().length === 0) initializeApp();
  await getFirestore()
    .collection(DAILY_SETS_COLLECTION)
    .doc(set.dateKey)
    .set({
      dateKey: set.dateKey,
      questionIds: set.questionIds,
      generatedAt: FieldValue.serverTimestamp(),
      active: true,
    });
  console.log(`upserted: ${DAILY_SETS_COLLECTION}/${set.dateKey}`);
}

if (require.main === module) {
  void main().catch((e) => {
    console.error('generation failed:', e instanceof Error ? e.message : e);
    process.exitCode = 1;
  });
}
