# NEET Question Bank — CLI Prompt + Roadmap

---

## SYSTEM PROMPT (paste this into your CLI)

```
You are a NEET question bank generator. You output questions strictly conforming to this schema:

{
  "id": string,              // format: PHY-XXXX / CHE-XXXX / BIO-XXXX, continuing from current max
  "subject": string,         // exactly: "Physics", "Chemistry", or "Biology"
  "chapter": string,         // exact NCERT chapter name, Class 11 or 12
  "ncert_class": int,        // 11 or 12
  "topic": string,           // sub-topic within chapter
  "difficulty": string,      // exactly: "Easy", "Medium", or "Hard"
  "bloom_level": string,     // exactly: "recall", "application", or "analysis"
  "question_text": string,
  "options": [string, string, string, string],  // exactly 4, all must be distinct
  "correct_option": string,  // exactly: "A", "B", "C", or "D"
  "explanation": string,     // full teacher-style, not just "B is correct"
  "common_wrong_reasoning": {  // only for wrong options with a real nameable misconception
    "A/B/C/D": string
  },
  "neet_pyq_year": [int] or null,
  "avg_time_seconds": int,   // defaults: Easy=45, Medium=75, Hard=110
  "diagram": null            // always null — no diagram questions
}

HARD RULES — never break these:
1. All 4 options must be distinct — no two options can be the same or near-identical
2. correct_option must actually be correct — verify against the real formula or NCERT fact before finalising
3. Distractors must be named errors (e.g. "forgot valency z", "used Celsius in Kelvin formula") — not random wrong values
4. No question stem may duplicate an existing one — vary parameters meaningfully
5. Numerical answers must be computed, never asserted
6. Biology questions must come from NCERT facts only — no content from third-party banks
7. Output must be valid JSON — no markdown, no commentary outside the array

TARGET for this session:
- Subject: Biology
- NCERT Class: [11 or 12 — specify]
- Chapter: [specify]
- Count: [specify]
- Difficulty mix: Easy 30% / Medium 50% / Hard 20%
- bloom_level mix: recall 40% / application 40% / analysis 20%
- ID range: continue from BIO-XXXX

Output a JSON array of questions. Nothing else.
```

---

## ROADMAP

### What the priorities are based on

- **P0 and P1** are spec-driven — the NEET exam pattern is public and fixed (45 Physics / 45 Chemistry / 90 Biology). These gaps exist against a known target, no student data needed to confirm them.
- **P2** is the observation instrument — this is where you start measuring real student behaviour.
- **P3** is entirely conditional on what P2 shows. Nothing here gets built on assumption.

---

### P0 — Fix before anything else

**Rebalance Biology to 1,500–2,000 questions**

Current state: Physics 2,716 / Chemistry 1,567 / Biology 749
Exam spec: 45 Physics / 45 Chemistry / 90 Biology

Biology is the heaviest-weighted subject in the exam and the thinnest in the bank. Every downstream feature — mock tests, coverage claims, student performance tracking — is unreliable until this is fixed.

How:
- Extend `bio_bank.py` using the same method already proven: ExamSIDE + SATHEE/eSaral weightage analysis to identify which chapters to prioritise
- Use the CLI prompt above, chapter by chapter
- Run the existing validator after each batch — duplicate stem detection is already in place

Target distribution within Biology:
- Easy 30% / Medium 50% / Hard 20%
- recall 40% / application 40% / analysis 20%

---

### P1 — Extend question types (text-only, no new infrastructure)

**Add assertion-reason format (~100–150 questions, Biology + Chemistry priority)**

Assertion-reason appears in real NEET papers and is completely absent from the current bank. It's text-only — no images, no new pipeline — just a schema extension.

Schema addition:
```json
{
  "type": "assertion_reason",
  "assertion": "Mitochondria have their own DNA.",
  "reason": "Mitochondria are believed to have originated from free-living prokaryotes.",
  "options": [
    "Both assertion and reason are true, and reason is the correct explanation",
    "Both assertion and reason are true, but reason is not the correct explanation",
    "Assertion is true but reason is false",
    "Assertion is false but reason is true"
  ],
  "correct_option": "A"
}
```

Add `"type": "assertion_reason"` as an optional field — existing questions default to `"type": "mcq"` so nothing breaks.

Priority chapters for assertion-reason:
- Biology: Molecular Basis of Inheritance, Cell Cycle, Photosynthesis, Human Physiology
- Chemistry: Electrochemistry, Chemical Kinetics, Coordination Compounds

---

### P2 — Build the validation interface

**Simple web quiz app — purpose is student feedback, not a polished product**

Stack: React + JSON (no Flutter, no Firebase yet)

Minimum features needed for useful validation:
- Subject filter (Physics / Chemistry / Biology)
- Timed question mode (uses `avg_time_seconds` from schema)
- Score at end with correct/incorrect breakdown
- At least one way for students to flag a question as wrong or confusing

What you're measuring:
- Which subjects students gravitate toward vs avoid
- Where they drop off — too hard, too repetitive, wrong difficulty calibration
- Whether they return (retention is the real signal, not first-session score)
- Whether numerical-heavy Physics/Chemistry practice is what they actually want

Do not build mock-test mode, performance tracking, or accounts at this stage. Those decisions depend on what you observe here.

---

### P3 — Full app build (only after P2 data)

Build only once P2 tells you students use it and what they actually need.

Likely stack: Flutter + Firebase
Features that make sense at this stage:
- Performance tracking by chapter and topic (schema already supports this — `chapter`, `topic`, `bloom_level` are all tagged)
- Full mock test mode (45/45/90 split, timed, NTA-style UI)
- Freemium structure — free tier for practice, paid for mock tests + analytics
- Push notifications for daily practice streaks

What P2 might change about P3:
- If Biology engagement is low → invest in diagram questions before full build
- If students want more conceptual over numerical → rebalance generator templates
- If drop-off is early → UX problem, not content problem — redesign before scaling

---

### Deliberately deferred — do not touch until P3

**Diagram-based questions**

Reasons:
1. Requires actual image assets — ray diagrams, circuit networks, Punnett squares, anatomy figures. That's a separate project from question generation.
2. A diagram question with a wrong or misleading figure is actively harmful — worse than no diagram question.
3. The schema already supports it (`"diagram": "BIO-D07.png"` → `assets/practice/diagrams/`). The infrastructure hook is there. The asset pipeline is not.

Revisit after P3 is live and you have real usage data to justify the effort.

---

## Quick reference — current bank state

| Subject   | Questions | Exam weight | Gap        |
|-----------|-----------|-------------|------------|
| Physics   | 2,716     | 45 / 180    | Overbuilt  |
| Chemistry | 1,567     | 45 / 180    | Overbuilt  |
| Biology   | 749       | 90 / 180    | ← Fix P0   |
| **Total** | **5,032** |             |            |

| Type             | Count | Share |
|------------------|-------|-------|
| Numerical        | 4,297 | 85%   |
| Conceptual/theory| 735   | 15%   |
| Assertion-reason | 0     | —     |
| Diagram-based    | 0     | —     |
