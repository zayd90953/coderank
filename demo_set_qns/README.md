# demo_set_qns — NEET Question Bank (5,900+ questions, 4 formats)

A demonstration bank of **5,891 questions** built to the structure defined in
[`QUESTION_SCHEMA.md`](../QUESTION_SCHEMA.md), extended with three additional
question formats. (The previous generated batch, NEET-9060…14041, has since been copied
into the main bank, so all new IDs start at **NEET-15000**.)

> **Status update:** this bank has since been MERGED into the shipped bank
> (`lib/features/practice/data/questions.json`, 4,982 → 10,873 questions) via
> [`merge_demo_bank.py`](merge_demo_bank.py), including all 220 SVG diagrams.
> The folder remains the reproducible source of truth for those questions.

## Contents

| File / dir | Purpose |
|---|---|
| `demo_questions.json` | Batch 1 — the original 15 hand-authored questions |
| `demo_questions_batch2.json` | Batch 2 — 35 questions (12 authentic PYQ transcriptions + 23 originals) |
| `demo_questions_generated.json` | The scaled bank — 5,841 questions (NEET-15000 → NEET-20840) |
| `diagrams/` | 220 SVG figures for the diagram-based questions (D0001.svg …) |
| `validate_demo_questions.py` | Validator: schema rules, duplicate stems, ID collisions, SVG well-formedness, format rules |
| `generators/` | Reproducible question-generation pipeline (Python, stdlib only) |
| `APP_INTEGRATION_NOTES.md` | What changes in the app if this bank replaces the current one |

## Distribution (full bank incl. batches 1–2)

| Subject | Count | Exam weight | | Difficulty | Count |
|---|---|---|---|---|---|
| Biology | **1,751** | 90/180 | | Easy | 1,652 |
| Physics | 2,678 | 45/180 | | Medium | 3,617 |
| Chemistry | 1,462 | 45/180 | | Hard | 622 |

The P0 rebalance from `neet_cli_prompt.md` is done: Biology (the exam's
heaviest subject) grew from 749 to 1,751, inside the recommended 1,500–2,000
band, funded by trimming the overbuilt Physics/Chemistry quotas.

## Question formats

| Format | Count | How it works |
|---|---|---|
| Plain MCQ | 5,557 | numerical + conceptual, as before |
| **Assertion–Reason** | 79 | canonical NEET option set, hand-verified truth values; verdict mix A:68 / B:6 / C:2 / D:3 |
| **Statement-match** | 35 | three statements, correct combination **computed** from fact tuples; key spread A:12 / B:8 / C:10 / D:5 |
| **Diagram-based** | 220 | SVG figure + question; answer computed from the same parameters that draw the figure |

New fields: `"type"` (`mcq` default, `assertion_reason`, `statement_match`) and
a non-null `"diagram"` (filename in `diagrams/`). Everything else in the schema
is unchanged, and every question still passes the original field checks.

## The diagram pipeline (stdlib-only SVG)

No matplotlib/Pillow exists in this environment — and SVG is a better fit
anyway: pure-text XML, diffable, reproducible, renders in Flutter via
`flutter_svg`, and (critically) **machine-verifiable**.

- `generators/svg_diagrams.py` — primitive library (lines, arrows, polygons,
  arcs, axes, circuit symbols: resistor zig-zags, battery plates). Selftest:
  XML well-formedness, arrowhead-tip geometry, escaping, determinism (8/8).
- `generators/diagram_questions.py` — 15 figure families: series circuit +
  ammeter, balanced Wheatstone bridge, resistor colour code, magnetic force
  direction, LC phasors, converging-lens image, YDSE fringe width, v–t graph
  area, coordination-complex oxidation state, titration curve (pH = pKa at
  half-equivalence drawn ON the curve), lever balance, replication fork,
  pedigree, energy pyramid, ECG rate.
- **Correctness contract**: every template parameterises `draw -> compute ->
  distract`. The answer and every distractor are *calculated from the same
  values printed in the figure*, so the diagram can never contradict the key.
  Spot-verified: Wheatstone labels `P = 5 Ω, Q = 6 Ω, R = 3 Ω` ↔ stem values
  match; titration mark sits exactly at pH = pKa on the drawn curve.
- Subject split: Physics 196, Chemistry 9, Biology 15.

## Copyright policy — what was sourced and how

Copying question text/options/explanations from commercial banks (MTG,
Arihant, Allen, etc.) would be a copyright violation and was **not done**.
The bank is built from four copyright-safe layers:

1. **Authentic PYQ transcriptions (52 questions, batches 1–2).** Real
   NEET exam-paper questions are public examination content. Each carries its
   true year in `neet_pyq_year`.
2. **Curated original factual MCQs (~330 questions).** Hand-authored on
   NCERT *facts* (facts are not copyrightable), fully original wording.
   Banks: `bio_bank.py`, `bio_bank2.py` (+bloom defaults) and the new
   `bio_bank3.py` (58 entries: Reproduction, Genetics, Molecular Basis,
   Evolution), `bio_bank4.py` (68 entries: Cell, Biomolecules, Plant
   Physiology, Human Physiology, Diversity) — both with explicit difficulty
   AND bloom per entry. The AR and statement-match modules are also fully
   hand-authored for the same reason: their verdicts cannot be safely
   auto-generated.
3. **Computed template questions (the bulk).** 80 parameterised templates
   (37 Physics, 24 Chemistry, 10+9 Biology) plus the 15 diagram families.
   Answers are **calculated from the real formula** — m = MIt/(zF),
   μ = √(n(n+2)), Chargaff, Hardy–Weinberg 2pq, codon table, S = C·A^z,
   dN/dt = rN(K−N)/K, semiconservative replication fractions, … Distractors
   are named errors, not noise.
4. **Weightage-driven coverage.** What to cover was chosen from ExamSIDE's
   PYQ index (2000–2026), eSaral chapter weightages, SATHEE (IIT-Kanpur) and
   Collegedunia analyses — never copied from them.

`neet_pyq_year` stays honest: only questions genuinely modelled on an
identifiable PYQ family carry a year; everything else is `null`.

## Quality machinery (`generators/`)

- **Selftest hooks, 26,000+ runs** — every template family plus the diagram
  selftest (400 runs): options pairwise distinct as *rendered strings*,
  correct letter set, substantive explanations, SVG files present and
  well-formed. Current status: **0 failures**.
- **Selftest-caught fixes this round** (why the hooks exist): a wrong-answer
  bug in the coordination-complex diagram template (+1 instead of +3 for
  [MCl₄]⁻), a μm-vs-mm units error in the YDSE template, a missing ½ factor
  in a v–t distractor, and several parameter-collision asserts.
- **Seeded RNG** — byte-for-byte reproducible; regeneration diffs cleanly.
- **Letter shuffling after value verification**, misconception dictionaries
  remapped to final letters automatically.
- **Cross-bank protection** — the generator pre-loads every main-bank stem
  into its dedupe set, so a regenerated question can never duplicate one
  already shipped in the app (82 such collisions were avoided this run).
- **Validator** now also enforces: `type` vocabulary, canonical AR options,
  statement-match structure, diagram files existing + parsing as SVG,
  duplicate stems across the whole folder, ID collisions with the main bank.

### Regenerating

```bash
python demo_set_qns/generators/generate_bank.py   # writes JSON + SVGs, cleans orphans
python demo_set_qns/validate_demo_questions.py    # exit 0 = all pass
```

Quotas live in `generate_bank.py` (`QUOTAS`, `TARGET_TOTAL`); scaling is a
config change, not new code. Biology's computed headroom is small (its
`bio_templates`/`bio_templates2` families saturate) — more Biology means
extending the curated banks, which is the correct trade for factual subjects.

## Honest caveats

- **Expert review before merging into the live bank is still recommended** —
  one teacher pass per template family and per curated bank.
- Bloom skew: computed questions are overwhelmingly `application`; the
  curated banks carry the `recall`/`analysis` load. The AR/SM formats are all
  `analysis` by nature.
- AR verdict mix is A-heavy (68/79) — inherent to the format when most pairs
  are constructed as true-and-explains; mitigated by the canonical (never
  shuffled) option order, which makes letter-guessing useless.
- Diagrams are deliberately schematic (labelled, to scale where the physics
  demands); rich anatomical artwork remains out of scope for a generator.
- Diagram questions need app-side support to display: see
  `APP_INTEGRATION_NOTES.md` §4 for the `flutter_svg`/pubspec requirements.
