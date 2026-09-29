"""Orchestrator: assembles the full demo bank (~5,250 questions).

Composition strategy (copyright-safe by design):
  1. CURATED  — hand-authored factual questions (bio_bank, bio_bank2, bio_bank3,
                bio_bank4) built on non-copyrightable NCERT facts, original
                wording. bank3/bank4 carry explicit difficulty + bloom.
  2. FORMATS  — assertion-reason (hand-verified truth values, canonical
                options) and statement-match (key computed from fact tuples).
  3. DIAGRAM  — diagram questions whose answers are computed from the same
                parameters that draw the SVG figure (svg_diagrams.py ->
                demo_set_qns/diagrams/*.svg).
  4. COMPUTED — parameterised templates (physics/chemistry/bio_templates +
                bio_templates2) whose answers are CALCULATED from real
                formulas, never guessed.

Every question passes: stem-level dedupe -> ID assignment (NEET-9060+) ->
difficulty-defaulted avg_time -> letter assignment (randomised by helpers).

Run:  python demo_set_qns/generators/generate_bank.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import assertion_reason
import bio_bank
import bio_bank2
import bio_bank3
import bio_bank4
import bio_templates
import bio_templates2
import chemistry_templates
import diagram_questions
import physics_templates
import statement_match
from common import assign_letters, remap_cwr

HERE = Path(__file__).parent.parent  # demo_set_qns/
OUT_FILE = HERE / "demo_questions_generated.json"
DIAGRAM_DIR = HERE / "diagrams"

DEFAULT_TIMES = {"Easy": 45, "Medium": 75, "Hard": 110}

# P0 rebalance (neet_cli_prompt.md): Biology is the exam's heaviest subject
# (90/180) and was the thinnest in the bank. Physics/Chemistry trimmed to
# make room. Total = 5,200 generated + 50 shipped = 5,250.
QUOTAS = {"Physics": 2450, "Chemistry": 1400, "Biology": 1350}
TARGET_TOTAL = 5200          # includes the 50 questions already shipped
EXISTING_COUNT = 50
MAX_ATTEMPTS_FACTOR = 400     # attempts per quota unit before giving up

# The main bank (lib/features/practice/data/questions.json) has absorbed the
# previous demo batch (NEET-9060..14041), so new ids start above that block.
ID_BASE = 15000
MAIN_BANK = HERE.parent / "lib" / "features" / "practice" / "data" / "questions.json"

SUBJECT_MODULES = {
    "Physics": physics_templates,
    "Chemistry": chemistry_templates,
    "Biology": bio_templates,       # volume top-up; bio_templates2 added below
}
TOPUP_ORDER = ["Biology", "Physics", "Chemistry"]  # protect the P0 subject


def finish_curated(entry: tuple) -> dict:
    """bio_bank / bio_bank2 format (11 fields, wrongs as a list, bloom fixed)."""
    (chapter, ncert_class, topic, stem, correct, wrongs, explanation,
     misconceptions, difficulty, pyq) = entry
    answers = [correct] + list(wrongs)
    options, letter, remap = assign_letters(answers)
    cwr = {remap[k]: v for k, v in misconceptions.items() if k in remap}
    return {
        "id": "",
        "subject": "Biology",
        "chapter": chapter,
        "ncert_class": ncert_class,
        "topic": topic,
        "difficulty": difficulty,
        "bloom_level": "recall",
        "question_text": stem,
        "options": options,
        "correct_option": letter,
        "explanation": explanation,
        "common_wrong_reasoning": cwr,
        "neet_pyq_year": pyq,
        "diagram": None,
    }


def finish_curated_flat(entry: tuple) -> dict:
    """bio_bank3 / bio_bank4 format (13 fields, wrongs flat, explicit bloom)."""
    (chapter, ncert_class, topic, stem, correct, w1, w2, w3,
     explanation, misconceptions, difficulty, bloom, pyq) = entry
    answers = [correct, w1, w2, w3]
    options, letter, remap = assign_letters(answers)
    cwr = {remap[k]: v for k, v in misconceptions.items() if k in remap}
    return {
        "id": "",
        "subject": "Biology",
        "chapter": chapter,
        "ncert_class": ncert_class,
        "topic": topic,
        "difficulty": difficulty,
        "bloom_level": bloom,
        "question_text": stem,
        "options": options,
        "correct_option": letter,
        "explanation": explanation,
        "common_wrong_reasoning": cwr,
        "neet_pyq_year": pyq,
        "diagram": None,
    }


def generate_unique(templates_module, quota: int, seen: set) -> tuple[list[dict], bool]:
    """Generate up to `quota` unique questions from a module with TEMPLATES."""
    out: list[dict] = []
    attempts = 0
    max_attempts = quota * MAX_ATTEMPTS_FACTOR
    while len(out) < quota and attempts < max_attempts:
        attempts += 1
        template = templates_module.RNG.choice(templates_module.TEMPLATES)
        try:
            q = template()
        except AssertionError:
            continue  # degenerate parameter draw; skip
        key = (q["subject"], q["question_text"])
        if key in seen:
            continue
        seen.add(key)
        out.append(q)
    sat = attempts >= max_attempts
    return out, sat


def cleanup_orphan_svgs(referenced: set[str]) -> int:
    """Delete SVGs in diagrams/ that no shipped question references."""
    removed = 0
    if DIAGRAM_DIR.exists():
        for f in DIAGRAM_DIR.glob("*.svg"):
            if f.name not in referenced:
                f.unlink()
                removed += 1
    return removed


def load_main_bank_stems() -> set[tuple[str, str]]:
    """Pre-seed the dedupe set with main-bank stems so a regenerated question
    can never duplicate one already shipped in the app's bank."""
    stems: set[tuple[str, str]] = set()
    if MAIN_BANK.exists():
        with open(MAIN_BANK, encoding="utf-8") as f:
            for q in json.load(f):
                subj = q.get("subject")
                text = q.get("question_text") or q.get("question")
                if subj and text:
                    stems.add((subj, text.strip()))
    return stems


def main() -> None:
    seen: set[tuple[str, str]] = load_main_bank_stems()
    all_questions: list[dict] = []

    def add(qs: list[dict]) -> None:
        """Append questions whose stems are globally unique."""
        for q in qs:
            key = (q["subject"], q["question_text"])
            if key in seen:
                continue
            seen.add(key)
            all_questions.append(q)

    # --- 1. curated banks -----------------------------------------------------
    n0 = len(all_questions)
    for entry in bio_bank.ENTRIES + bio_bank2.ENTRIES:
        add([finish_curated(entry)])
    for entry in bio_bank3.ENTRIES + bio_bank4.ENTRIES:
        add([finish_curated_flat(entry)])
    print(f"curated: {len(all_questions) - n0} questions")

    # --- 2. new formats: assertion-reason + statement-match --------------------
    n0 = len(all_questions)
    add(assertion_reason.build())
    add(statement_match.build())
    print(f"formats (AR + statement-match): {len(all_questions) - n0} questions")

    # --- 3. diagram questions ---------------------------------------------------
    # NOTE: generate_unique dedupes against `seen` itself, so its output is
    # extended directly (an add() re-check would drop every question).
    n0 = len(all_questions)
    dia, sat = generate_unique(diagram_questions, 220, seen)
    all_questions.extend(dia)
    print(f"diagram: {len(dia)} questions{' (SATURATED)' if sat else ''}")

    # --- 4. computed templates per subject --------------------------------------
    stats = {}
    for subject, quota in QUOTAS.items():
        module = SUBJECT_MODULES[subject]
        gen, saturated = generate_unique(module, quota, seen)
        all_questions.extend(gen)
        subj = gen[0]["subject"] if gen else subject
        stats[subj] = (len(gen), saturated)
        flag = " (SATURATED — unique-stem capacity reached)" if saturated else ""
        print(f"computed {subj}: {len(gen)}{flag}")
    # bio_templates2 on top of the bio quota
    gen, sat = generate_unique(bio_templates2, 400, seen)
    all_questions.extend(gen)
    print(f"computed Biology (templates2): {len(gen)}{' (SATURATED)' if sat else ''}")

    # --- 5. top up to target, protecting Biology first ---------------------------
    top_i = 0
    while len(all_questions) + EXISTING_COUNT < TARGET_TOTAL:
        subject = TOPUP_ORDER[top_i % len(TOPUP_ORDER)]
        top_i += 1
        module = SUBJECT_MODULES[subject]
        gen, sat = generate_unique(module, 50, seen)
        if not gen:
            if subject == "Biology":
                gen, _ = generate_unique(bio_templates2, 50, seen)
            if not gen:
                break
        all_questions.extend(gen)

    # --- 6. assign ids, default times --------------------------------------------
    next_id = ID_BASE
    referenced_diagrams: set[str] = set()
    for q in all_questions:
        q["id"] = f"NEET-{next_id}"
        next_id += 1
        q.setdefault("avg_time_seconds", DEFAULT_TIMES[q["difficulty"]])
        q["avg_time_seconds"] = DEFAULT_TIMES[q["difficulty"]]
        if q.get("neet_pyq_year") is not None and not isinstance(q["neet_pyq_year"], list):
            q["neet_pyq_year"] = [q["neet_pyq_year"]]
        q.setdefault("bloom_level", "recall")
        if q.get("diagram"):
            referenced_diagrams.add(q["diagram"])

    # --- 7. remove orphan SVGs, write ---------------------------------------------
    removed = cleanup_orphan_svgs(referenced_diagrams)

    with open(OUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_questions, f, indent=2, ensure_ascii=False)

    # --- 8. census -------------------------------------------------------------------
    def dist(key):
        d = {}
        for q in all_questions:
            d[q[key]] = d.get(q[key], 0) + 1
        return dict(sorted(d.items()))

    qtypes = {"diagram": 0, "assertion_reason": 0, "statement_match": 0, "mcq": 0}
    for q in all_questions:
        t = q.get("type")
        if q.get("diagram"):
            qtypes["diagram"] += 1
        elif t in ("assertion_reason", "statement_match"):
            qtypes[t] += 1
        else:
            qtypes["mcq"] += 1

    print(f"\nwritten: {len(all_questions)} questions -> {OUT_FILE.name}")
    print(f"orphan SVGs removed: {removed}; referenced: {len(referenced_diagrams)}")
    print("subjects:", dist("subject"))
    print("difficulty:", dist("difficulty"))
    print("bloom:", dist("bloom_level"))
    print("types:", qtypes)
    print(f"id range: NEET-{ID_BASE} .. NEET-{next_id - 1}")


if __name__ == "__main__":
    main()
