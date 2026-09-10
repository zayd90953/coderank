# demo_set_qns — NEET Demo Question Set

A small demonstration set of **15 schema-compliant NEET questions** built to the
exact structure defined in [`QUESTION_SCHEMA.md`](../QUESTION_SCHEMA.md).
This folder is self-contained — nothing in the existing app, question bank, or
schema was modified.

## Contents

| File | Purpose |
|---|---|
| `demo_questions.json` | 15 NEET questions (5 Physics, 5 Chemistry, 5 Biology) in the `QUESTION_SCHEMA.md` JSON format |
| `validate_demo_questions.py` | Standalone validator that checks every field rule in the schema |
| `README.md` | This file |

## Why these questions

All questions were **authored fresh for this demo set** (original wording — no
copyrighted question text is reproduced). They are modelled on:

- **NEET UG exam pattern (2024–25)**: 180 compulsory questions — Physics 45,
  Chemistry 45, Biology 90; +4 for correct, −1 for incorrect.
- **High-weightage chapters** per published paper analyses, e.g.
  Electrostatic Potential & Capacitance, Current Electricity, Ray Optics,
  Laws of Motion, Coordination Compounds, Equilibrium, Electrochemistry,
  Biomolecules, Molecular Basis of Inheritance, Human/Neural Physiology,
  Principles of Inheritance, Photosynthesis.
- **Real PYQ patterns**, cited per question via the `neet_pyq_year` field:
  - NEET 2024: "12 pF capacitor with a 50 V battery" energy calculation
    (NEET-9001)
  - NEET 2019: peroxide-effect / anti-Markovnikov HBr addition (NEET-9006)
  - NEET 2016: 999-base RNA frameshift-style coding question (NEET-9012)
  - PYQ family: Hershey–Chase bacteriophage experiment (NEET-9011)

`neet_pyq_year` is an **honest** field: only questions genuinely modelled on an
identifiable PYQ carry a year; the rest are `null` rather than padded.

## Schema compliance

Every question carries all required fields from `QUESTION_SCHEMA.md`:

- `id` — unique, in the existing bank's `NEET-XXXX` convention, using the
  `9001–9015` block so it can never collide with the main bank's
  `NEET-0001 … NEET-2500`.
- `subject` / `chapter` / `ncert_class` / `topic` — exact NCERT chapter names
  and class (11 or 12).
- `difficulty` — Easy / Medium / Hard (defaults 45 s / 75 s / 110 s applied to
  `avg_time_seconds`).
- `bloom_level` — recall / application / analysis per the schema guide.
- `question_text`, `options` (exactly 4), `correct_option` (A–D).
- `explanation` — full teacher-style working, never "B is correct".
- `common_wrong_reasoning` — one genuine misconception per wrong option,
  included only where a real, nameable misconception exists.

Optional fields used where applicable: `neet_pyq_year`, `avg_time_seconds`
(`diagram` is `null` throughout — the demo set is deliberately diagram-free so
no new asset files are needed).

## Distribution

| Subject | Count | Easy | Medium | Hard |
|---|---|---|---|---|
| Physics | 5 | 0 | 5 | 0 |
| Chemistry | 5 | 1 | 3 | 1 |
| Biology | 5 | 2 | 3 | 0 |

Biology is deliberately not over-weighted here; in a full bank it should scale
towards the exam's 90/180 Biology share.

## Validate

```bash
python demo_set_qns/validate_demo_questions.py
```

Exit code 0 = all 15 questions pass every schema rule, including a uniqueness
check of IDs against the main 2,500-question bank.
