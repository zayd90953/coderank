#!/usr/bin/env python3
"""Validate demo_questions.json against QUESTION_SCHEMA.md.

Run from the project root:  python demo_set_qns/validate_demo_questions.py
Exit code 0 = all questions pass, 1 = validation errors found.
"""

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

HERE = Path(__file__).parent
DATA_FILE = HERE / "demo_questions.json"
DATA_FILE_BATCH2 = HERE / "demo_questions_batch2.json"
DATA_FILE_GENERATED = HERE / "demo_questions_generated.json"
MAIN_BANK = HERE.parent / "lib" / "features" / "practice" / "data" / "questions.json"

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


with open(DATA_FILE, encoding="utf-8") as f:
    questions = json.load(f)
if DATA_FILE_BATCH2.exists():
    with open(DATA_FILE_BATCH2, encoding="utf-8") as f:
        questions += json.load(f)
if DATA_FILE_GENERATED.exists():
    with open(DATA_FILE_GENERATED, encoding="utf-8") as f:
        questions += json.load(f)

if not isinstance(questions, list) or not questions:
    print("FATAL: demo_questions.json must be a non-empty JSON array.")
    sys.exit(1)

# --- ID uniqueness within the demo set and against the main bank -----------
demo_ids = [q.get("id") for q in questions]
for qid in set(d for d in demo_ids if d):
    if demo_ids.count(qid) > 1:
        err(qid, f"duplicate id within demo set ({demo_ids.count(qid)} occurrences)")

# --- duplicate stems within the generated bank -----------------------------
stem_counts: dict[tuple[str, str], int] = {}
for q in questions:
    key = (q.get("subject"), q.get("question_text"))
    stem_counts[key] = stem_counts.get(key, 0) + 1
for (subj, stem), count in stem_counts.items():
    if count > 1:
        err(f"STEM-DUP x{count}", f"[{subj}] {stem[:70]}...")

main_ids = set()
if MAIN_BANK.exists():
    with open(MAIN_BANK, encoding="utf-8") as f:
        main_ids = {q["id"] for q in json.load(f)}
    print(f"Main bank loaded: {len(main_ids)} ids")
else:
    print("NOTE: main bank not found; skipping cross-bank id check")

# --- Per-question field checks ---------------------------------------------
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
    if q.get("id") in main_ids:
        err(qid, "id collides with an existing question in the main bank")

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

    # Optional: diagram — must be a real, well-formed SVG in demo_set_qns/diagrams/
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
print("Distribution:",
      {s: sum(1 for q in questions if q["subject"] == s)
       for s in sorted(SUBJECTS)})
n_dia = sum(1 for q in questions if q.get("diagram"))
n_ar = sum(1 for q in questions if q.get("type") == "assertion_reason")
n_sm = sum(1 for q in questions if q.get("type") == "statement_match")
print(f"formats: {n_ar} assertion-reason, {n_sm} statement-match, "
      f"{n_dia} with diagrams, rest plain MCQ")
