# demo_set_qns — NEET Question Bank (5,000+ schema-compliant questions)

A demonstration bank of **5,032 questions** built to the exact structure
defined in [`QUESTION_SCHEMA.md`](../QUESTION_SCHEMA.md). This folder is
self-contained — nothing in the existing app, question bank, or schema was
modified.

## Contents

| File | Purpose |
|---|---|
| `demo_questions.json` | Batch 1 — the original 15 hand-authored questions |
| `demo_questions_batch2.json` | Batch 2 — 35 questions (12 authentic PYQ transcriptions + 23 originals) |
| `demo_questions_generated.json` | The scaled bank — 4,982 questions (NEET-9060 → NEET-14041) |
| `validate_demo_questions.py` | Validator enforcing every schema rule over all files |
| `generators/` | Reproducible question-generation pipeline (Python, stdlib only) |
| `APP_INTEGRATION_NOTES.md` | What changes in the app if this bank replaces the current one |

## Distribution (full bank incl. batches 1–2)

| Subject | Count | | Difficulty | Count |
|---|---|---|---|---|
| Physics | 2,716 | | Easy | 1,584 |
| Chemistry | 1,567 | | Medium | 2,758 |
| Biology | 749 | | Hard | 640 |

ID ranges: batches 1–2 use `NEET-9001…9050`; the generated bank uses
`NEET-9060…14041`. The validator cross-checks all IDs against the main bank
(`NEET-0001…2500`) — zero collisions.

## Copyright policy — what was sourced and how

Copying question text, options, or explanations from commercial question
banks/coaching material (MTG, Arihant, Allen modules, etc.) would be a
copyright violation, and was **not done**. Instead the bank is built from
three copyright-safe layers:

1. **Authentic PYQ transcriptions (52 questions, batches 1–2).** Real NEET
   exam-paper questions are government examination content, widely republished
   for preparation. Each carries its true year in `neet_pyq_year`.
2. **Curated original factual MCQs (~90 questions).** Hand-authored questions
   built on NCERT *facts* (facts are not copyrightable) with fully original
   wording, explanations, and misconception mappings. Sources consulted to
   decide what to cover: ExamSIDE's year-wise PYQ index (2000–2026), eSaral's
   chapter weightage analyses, SATHEE (IIT-Kanpur) and Collegedunia chapter
   breakdowns, and BYJU'S PYQ collections.
3. **Computed template questions (the bulk).** 71 parameterised templates
   (37 Physics, 24 Chemistry, 10 Biology) modelled on the recurring NEET
   archetypes identified from those sources. Each template draws random
   parameters from a physically/chemically sensible range and **computes** the
   correct answer from the real formula — no answer is ever asserted. Wide,
   continuous parameter spaces keep stems unique (the 5,000-question run
   produced zero duplicate stems). Examples: V = E − Ir, R′ = n²R,
   m = MIt/(zF), μ = √(n(n+2)), Chargaff's rule, Hardy–Weinberg 2pq,
   codon-table translation.

`neet_pyq_year` remains an honest field: only questions genuinely modelled on
an identifiable PYQ family carry a year; everything else is `null`.

## Quality machinery (`generators/`)

- **Selftest hooks** — every template is run 300× (21,300 runs total): options
  must be pairwise distinct as *rendered strings*, the correct letter must be
  set, explanations must be substantive. Current status: **0 failures**.
- **Seeded RNG** (`common.py`) — the bank is byte-for-byte reproducible; the
  output diffs cleanly if templates change.
- **Letter shuffling after value verification** — correctness never depends on
  which letter the right answer lands on; misconception dictionaries are
  remapped to the final letters automatically.
- **Distractor provenance** — every wrong option comes from a *named
  misconception* ("forgot valency z", "used Celsius in η = 1 − Tc/Th",
  "used r³ instead of r² in Stokes' law"), not random noise. Collisions
  (when two misconception formulas agree for a parameter draw) are resolved
  deterministically, never by deleting a distractor silently.

### Regenerating

```bash
python demo_set_qns/generators/generate_bank.py   # writes demo_questions_generated.json
python demo_set_qns/validate_demo_questions.py    # exit 0 = all pass
```

The orchestrator's quotas live in `generate_bank.py` (`QUOTAS`,
`TARGET_TOTAL`); scaling to 10,000+ is a config change, not new code. Biology
is the limiting subject (factual questions are curated, not generated) — its
count grows by extending `bio_bank.py` / `bio_bank2.py` or the computed
bio templates.

## Schema compliance

Every question carries all required fields, with `common_wrong_reasoning` on
all computed/curated questions, `avg_time_seconds` defaulted per difficulty
(45/75/110 s), and `diagram: null` (no asset files needed). The validator also
rejects duplicate stems across the whole folder.

## Honest caveats

- **Expert review before merging into the live bank is strongly
  recommended.** The computed answers are machine-verified against the
  formulas, and spot checks passed, but a subject teacher should review each
  template family once before students see it.
- Diagram-based questions (graph reading, circuit/tracing figures) are absent
  by design — they need real assets and are a natural next phase.
- The generated bank emphasises numerical/analysis items in Physics and
  Chemistry; Biology leans on the curated set plus computation-friendly topics
  (genetics, molecular biology). Round out Biology by growing the curated
  banks if a 90:45:45 exam-weight split is desired.
