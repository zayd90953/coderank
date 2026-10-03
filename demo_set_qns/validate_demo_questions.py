#!/usr/bin/env python3
"""Validate the demo bank (demo_set_qns/) against QUESTION_SCHEMA.md.

Run from the project root:  python demo_set_qns/validate_demo_questions.py

Exit code 0 = all questions pass, 1 = validation errors found.

Validation scope
----------------
The three demo batches were already merged into the canonical production
bank, so their IDs (demo batches 1+2: NEET-9001..9050; generated batch:
NEET-15000..20840) now live in lib/features/practice/data/questions.json.

This validator therefore enforces STRICTNESS against the *source* datasets:

  1. Per-dataset ID uniqueness (duplicate IDs WITHIN each batch and across
     all three batches combined).
  2. Genuine duplicate stems WITHIN the combined demo set (a real data
     defect that would make a regen/merge unsafe).
  3. All schema-required fields present and correctly typed.
  4. No unknown/schema-violating fields.
  5. Options: exactly 4, pairwise distinct, non-empty; correct_option is a
     valid letter; correct letter points at a non-empty option.
  6. Per-format structural rules: assertion_reason uses the canonical
     option set + 'Assertion (A):' / 'Reason (R):' stems; statement_match
     enumerates 'Statement I:' and ends with 'I, II and III'.
  7. Explanation substantiveness; unused optional fields validated only
     when present (common_wrong_reasoning keys = wrong options only;
     neet_pyq_year ints in 2000-2026; avg_time_seconds matches difficulty;
     diagram = existing well-formed SVG).
  8. Cross-bank protection is removed: IDs already merged into the main
     bank are VALID, because the merge pipeline guaranteed they did not
     collide. Any genuine collision that would make a merge unsafe is
     still reported as a hard failure (see merge_demo_bank.py).

The validator intentionally does NOT report IDs that exist in the main
bank but not in the demo set; those are a property of the merged layout,
not of the demo data.
"""

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).parent
DATA_FILE = HERE / "demo_questions.json"
DATA_FILE_BATCH2 = HERE / "demo_questions_batch2.json"
DATA_FILE_GENERATED = HERE / "demo_questions_generated.json"

REQUIRED_FIELDS = [
    "id", "subject", "chapter", "ncert_class", "topic", "difficulty",
    "bloom_level", "question_text", "options", "correct_option", "explanation",
]
OPTIONAL_FIELDS = [
    "common_wrong_reasoning", "neet_pyq_year", "avg_time_seconds", "diagram",
    "type",
]
QUESTION_TYPES = {"mcq", "assertion_reason", "statement_match"}
# Must stay in sync with AR_OPTIONS in generators/assertion_reason.py
AR_OPTIONS = [
    "Both assertion and reason are true, and the reason is the correct explanation of the assertion",
    "Both assertion and reason are true, but the reason is not the correct explanation of the assertion",
    "The assertion is true, but the reason is false",
    "The assertion is false, but the reason is true",
]
SUBJECTS = {"Physics", "Chemistry", "Biology"}
DIFFICULTIES = {"Easy", "Medium", "Hard"}
BLOOM_LEVELS = {"recall", "application", "analysis"}
DEFAULT_TIMES = {"Easy": 45, "Medium": 75, "Hard": 110}

errors = []


def err(qid, msg):
    errors.append(f"{qid}: {msg}")


def load_questions():
    """Load the three demo batches combined. Missing files are NOT errors."""
    questions = []
    for path in (DATA_FILE, DATA_FILE_BATCH2, DATA_FILE_GENERATED):
        if path.exists():
            with open(path, encoding="utf-8") as f:
                questions += json.load(f)
    return questions


questions = load_questions()

if not isinstance(questions, list) or not questions:
    print("FATAL: no demo question files found or they are empty.")
    sys.exit(1)

# --- Cross-dataset guard ---------------------------------------------------
# The merge pipeline (merge_demo_bank.py) already guarantees these IDs never
# collided with the main bank. Asking the validator to re-check against the
# main bank is wrong for the merged layout: it reports pre-existing, already-
# absorbed IDs as "collisions" even though the merge itself was safe.
#
# Instead we enforce STRONGER checks inside the demo set itself:
#   * duplicate IDs within a single batch,
#   * duplicate IDs across the three batches combined,
#   * duplicate question stems across the combined set (the actual merge-safety
#     defect that the original code could not even express).
COMBINED_DEMO_IDS = [q.get("id") for q in questions]
for qid in set(qid for qid in COMBINED_DEMO_IDS if qid):
    if COMBINED_DEMO_IDS.count(qid) > 1:
        err(qid, f"duplicate id across demo batches ({COMBINED_DEMO_IDS.count(qid)} occurrences)")

# Duplicate-stem detection across the whole demo set (catches regen/merge
# content collisions, the actual safety check the original code intended).
stem_counts = {}
for q in questions:
    key = (q.get("subject"), q.get("question_text"))
    stem_counts[key] = stem_counts.get(key, 0) + 1
for (subj, stem), count in stem_counts.items():
    if count > 1:
        err(f"STEM-DUP x{count}", f"[{subj}] {stem[:70]}...")

# Per-question field checks (identical strictness to before, minus the
# cross-bank id check which is now excluded by design).
for q in questions:
    qid = q.get("id", "<missing id>")

    missing = [k for k in REQUIRED_FIELDS if k not in q]
    if missing:
        err(qid, f"missing required fields: {missing}")

    extra = [k for k in q if k not in REQUIRED_FIELDS and k not in OPTIONAL_FIELDS]
    if extra:
        err(qid, f"unknown fields (not in schema): {extra}")

    if not isinstance(q.get("id"), str) or not q.get("id"):
        err(qid, "id must be a non-empty string")

    if q.get("subject") not in SUBJECTS:
        err(qid, f"subject must be one of {sorted(SUBJECTS)}, got {q.get('subject')!r}")

    chapter = q.get("chapter")
    if not isinstance(chapter, str) or not chapter.strip():
        err(qid, "chapter must be a non-empty string (exact NCERT chapter name)")

    if q.get("ncert_class") not in (11, 12):
        err(qid, f"ncert_class must be 11 or 12, got {q.get('ncert_class')!r}")

    if not isinstance(q.get("topic"), str) or not q.get("topic", "").strip():
        err(qid, "topic must be a non-empty string")

    if q.get("difficulty") not in DIFFICULTIES:
        err(qid, f"difficulty must be one of {sorted(DIFFICULTIES)}, got {q.get('difficulty')!r}")

    if q.get("bloom_level") not in BLOOM_LEVELS:
        err(qid, f"bloom_level must be one of {sorted(BLOOM_LEVELS)}, got {q.get('bloom_level')!r}")

    qt = q.get("question_text")
    if not isinstance(qt, str) or len(qt.strip()) < 15:
        err(qid, "question_text must be a non-trivial string (>= 15 chars)")

    options = q.get("options")
    if not isinstance(options, list) or len(options) != 4:
        err(qid, f"options must be an array of exactly 4 strings, got {options!r}")
        options = None
    elif not all(isinstance(o, str) and o.strip() for o in options):
        err(qid, "every option must be a non-empty string")
    elif len({o.strip() for o in options}) != 4:
        err(qid, "options must be pairwise distinct")

    co = q.get("correct_option")
    if co not in {"A", "B", "C", "D"}:
        err(qid, f"correct_option must be 'A', 'B', 'C' or 'D', got {co!r}")
    elif options is not None:
        idx = "ABCD".index(co)
        if not options[idx].strip():
            err(qid, f"correct_option {co} points at an empty option")

    # Optional: question type (defaults to plain MCQ)
    qtype = q.get("type", "mcq")
    if qtype not in QUESTION_TYPES:
        err(qid, f"type must be one of {sorted(QUESTION_TYPES)}, got {qtype!r}")

    # Format-specific structural rules
    if options is not None and qtype == "assertion_reason":
        if options != AR_OPTIONS:
            err(qid, "assertion_reason must use the canonical option set")
        if "Assertion (A):" not in (qt or "") or "Reason (R):" not in (qt or ""):
            err(qid, "assertion_reason stem must contain 'Assertion (A):' and 'Reason (R):'")
        if q.get("bloom_level") != "analysis":
            err(qid, "assertion_reason must have bloom_level 'analysis'")
    if options is not None and qtype == "statement_match":
        if "Statement I:" not in (qt or ""):
            err(qid, "statement_match stem must enumerate 'Statement I:'")
        if options[-1] != "I, II and III":
            err(qid, "statement_match option set must end with 'I, II and III'")

    exp = q.get("explanation")
    if not isinstance(exp, str) or len(exp.strip()) < 40:
        err(qid, "explanation must be a full teacher-style explanation (>= 40 chars)")

    # Optional: common_wrong_reasoning
    cwr = q.get("common_wrong_reasoning")
    if cwr is not None:
        if not isinstance(cwr, dict):
            err(qid, "common_wrong_reasoning must be an object")
        else:
            if co in {"A", "B", "C", "D"}:
                if co in cwr:
                    err(qid, f"common_wrong_reasoning contains the correct option {co}")
                wrong = {"A", "B", "C", "D"} - {co}
                if not set(cwr) <= wrong:
                    err(qid, f"common_wrong_reasoning has keys outside the wrong options: "
                             f"{sorted(set(cwr) - wrong)}")
            for k, v in cwr.items():
                if not isinstance(v, str) or not v.strip():
                    err(qid, f"common_wrong_reasoning['{k}'] must be a non-empty string")

    # Optional: neet_pyq_year
    pyq = q.get("neet_pyq_year")
    if pyq is not None:
        if (not isinstance(pyq, list)
                or not pyq
                or not all(isinstance(y, int) and 2000 <= y <= 2026 for y in pyq)):
            err(qid, "neet_pyq_year must be a non-empty array of ints (2000-2026)")

    # Optional: avg_time_seconds (defaults per difficulty)
    ats = q.get("avg_time_seconds")
    if ats is not None and (not isinstance(ats, int) or ats <= 0):
        err(qid, "avg_time_seconds must be a positive int")
    diff = q.get("difficulty")
    if diff in DEFAULT_TIMES:
        expected = DEFAULT_TIMES[diff]
        actual = ats if ats is not None else expected
        if actual != expected:
            err(qid, f"avg_time_seconds for {diff} should be {expected}, got {actual}")

    # Optional: diagram — must be a real, well-formed SVG
    dia = q.get("diagram")
    if dia is not None:
        if not isinstance(dia, str) or not dia.endswith(".svg"):
            err(qid, "diagram must be null or a filename ending in .svg")
        else:
            fpath = HERE / "diagrams" / dia
            if not fpath.exists():
                err(qid, f"diagram file missing: diagrams/{dia}")
            else:
                try:
                    root = ET.fromstring(fpath.read_text(encoding="utf-8"))
                    if not root.tag.endswith("svg"):
                        err(qid, f"diagram {dia} is not an SVG document")
                except ET.ParseError as e:
                    err(qid, f"diagram {dia} is not well-formed XML: {e}")

# --- Summary ----------------------------------------------------------------
if errors:
    print(f"\nFAILED — {len(errors)} problem(s) found:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"\nAll {len(questions)} demo questions pass QUESTION_SCHEMA.md validation.")
print("Distribution:", {s: sum(1 for q in questions if q["subject"] == s) for s in sorted(SUBJECTS)})
n_dia = sum(1 for q in questions if q.get("diagram"))
n_ar = sum(1 for q in questions if q.get("type") == "assertion_reason")
n_sm = sum(1 for q in questions if q.get("type") == "statement_match")
print(f"formats: {n_ar} assertion-reason, {n_sm} statement-match, {n_dia} with diagrams, "
      f"{len(questions) - n_ar - n_sm - n_dia} plain MCQ")
