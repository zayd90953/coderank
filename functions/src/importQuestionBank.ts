/**
 * questionBank import pipeline (operator tool — never called by the app).
 *
 * Usage (run from functions/):
 *   npm run import:bank            → validate + dry-run summary (no writes)
 *   npm run import:bank -- --write → perform batched Firestore writes
 *
 * Requires Application Default Credentials (ADC) or FIREBASE_CONFIG for the
 * `coderank-6e6eb` project — i.e. `firebase login` / a service account.
 *
 * The trusted doc shape is exactly:
 *   questionBank/{questionId} = { subject, correctAnswer, optionCount,
 *                                 difficulty, active }
 * No question text, options, or explanations are ever written.
 */

interface ImportArgs {
  write: boolean;
}

function parseArgs(argv: string[]): ImportArgs {
  return { write: argv.includes('--write') };
}

async function main(): Promise<void> {
  const { write } = parseArgs(process.argv.slice(2));

  // Lazy imports keep `jest` runs of pure helpers free of admin overhead.
  const { loadProductionBankJson, validateProductionBank } = await import('./bankSource');
  const questions = loadProductionBankJson();
  const { docs, errors } = validateProductionBank(questions);

  console.log('── questionBank import ──────────────────────────────');
  console.log(`mode: ${write ? 'WRITE' : 'DRY-RUN (no data modified)'}`);
  console.log(`valid questions: ${docs.size}`);
  console.log(`validation errors: ${errors.length}`);

  if (errors.length > 0) {
    for (const e of errors.slice(0, 20)) console.error('  ✗ ' + e);
    if (errors.length > 20) console.error(`  … and ${errors.length - 20} more`);
    console.error('ABORT: fix validation errors before importing.');
    process.exitCode = 1;
    if (!write) return;
    return;
  }

  // Dry-run summary (shape only — no answer values printed).
  const bySubject = new Map<string, number>();
  const byOptions = new Map<number, number>();
  for (const d of docs.values()) {
    bySubject.set(d.subject, (bySubject.get(d.subject) ?? 0) + 1);
    byOptions.set(d.optionCount, (byOptions.get(d.optionCount) ?? 0) + 1);
  }
  console.log('by subject :', Object.fromEntries(bySubject));
  console.log('by options :', Object.fromEntries(byOptions));
  const sampleId = docs.keys().next().value as string | undefined;
  if (sampleId) {
    console.log(`sample doc : questionBank/${sampleId} = { subject, correctAnswer, optionCount, difficulty, active }`);
  }

  if (!write) {
    console.log('dry-run complete — re-run with --write to import.');
    return;
  }

  const { initializeApp, getApps } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  if (getApps().length === 0) initializeApp();
  const db = getFirestore();

  const entries = [...docs.entries()];
  const BATCH_SIZE = 500; // Firestore hard limit
  let written = 0;
  for (let i = 0; i < entries.length; i += BATCH_SIZE) {
    const batch = db.batch();
    for (const [id, doc] of entries.slice(i, i + BATCH_SIZE)) {
      batch.set(db.collection('questionBank').doc(id), doc);
    }
    await batch.commit();
    written += Math.min(BATCH_SIZE, entries.length - i);
    console.log(`  wrote ${written}/${entries.length}`);
  }
  console.log(`import complete: ${written} questionBank documents.`);
}

if (require.main === module) {
  void main().catch((e) => {
    console.error('import failed:', e instanceof Error ? e.message : e);
    process.exitCode = 1;
  });
}
