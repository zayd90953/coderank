"""Orchestrator: assembles the full demo bank (~5,000 questions).

Composition strategy (copyright-safe by design):
  1. CURATED  — hand-authored factual questions (bio_bank.py, bio_bank2.py)
                built on non-copyrightable NCERT facts, original wording.
  2. COMPUTED — parameterised templates (physics/chemistry/bio_templates.py)
                whose answers are CALCULATED from real formulas, never guessed.
                Continuous parameter spaces give effectively unlimited unique
                stems; finite-case templates saturate and stop contributing.

Every question passes through: stem-level dedupe -> ID assignment (NEET-9060+)
-> difficulty-defaulted avg_time -> letter assignment (already randomised by
the helpers). The output file is validated by validate_demo_questions.py.

Run:  python demo_set_qns/generators/generate_bank.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bio_bank
import bio_bank2
import bio_templates
import chemistry_templates
import physics_templates
from common import assign_letters, remap_cwr

HERE = Path(__file__).parent.parent  # demo_set_qns/
OUT_FILE = HERE / "demo_questions_generated.json"

DEFAULT_TIMES = {"Easy": 45, "Medium": 75, "Hard": 110}

TARGET_TOTAL = 5000          # includes the 50 questions already shipped
EXISTING_COUNT = 50
QUOTAS = {"Physics": 2600, "Chemistry": 1500, "Biology": 650}
TOPUP_SUBJECTS = ["Physics", "Chemistry"]  # unlimited-capacity subjects
MAX_ATTEMPTS_FACTOR = 400     # attempts per quota unit before giving up


def finish_curated(entry: tuple) -> dict:
    """Turn a bio_bank entry tuple into a schema-compliant question dict."""
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


def generate_unique(templates_module, quota: int, seen: set) -> tuple[list[dict], bool]:
    """Generate up to `quota` unique questions from a module with TEMPLATES."""
    out: list[dict] = []
    attempts = 0
    max_attempts = quota * MAX_ATTEMPTS_FACTOR
    n_templates = len(templates_module.TEMPLATES)
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


def main() -> None:
    seen: set[tuple[str, str]] = set()
    all_questions: list[dict] = []

    # --- 1. curated banks -----------------------------------------------------
    for entry in bio_bank.ENTRIES + bio_bank2.ENTRIES:
        q = finish_curated(entry)
        key = (q["subject"], q["question_text"])
        if key not in seen:
            seen.add(key)
            all_questions.append(q)
    print(f"curated: {len(all_questions)} questions")

    # --- 2. computed templates per subject ------------------------------------
    stats = {}
    for module, quota in [
        (physics_templates, QUOTAS["Physics"]),
        (chemistry_templates, QUOTAS["Chemistry"]),
        (bio_templates, QUOTAS["Biology"]),
    ]:
        gen, saturated = generate_unique(module, quota, seen)
        all_questions.extend(gen)
        subj = gen[0]["subject"] if gen else "?"
        stats[subj] = (len(gen), saturated)
        flag = " (SATURATED — unique-stem capacity reached)" if saturated else ""
        print(f"computed {subj}: {len(gen)}{flag}")

    # --- 3. top up to target from unlimited subjects ---------------------------
    top_i = 0
    while len(all_questions) + EXISTING_COUNT < TARGET_TOTAL:
        module = physics_templates if TOPUP_SUBJECTS[top_i % 2] == "Physics" else chemistry_templates
        top_i += 1
        gen, sat = generate_unique(module, 50, seen)
        if not gen:
            break
        all_questions.extend(gen)

    # --- 4. assign ids, default times ------------------------------------------
    next_id = 9060
    for q in all_questions:
        q["id"] = f"NEET-{next_id}"
        next_id += 1
        q.setdefault("avg_time_seconds", DEFAULT_TIMES[q["difficulty"]])
        q["avg_time_seconds"] = DEFAULT_TIMES[q["difficulty"]]
        if q.get("neet_pyq_year") is not None and not isinstance(q["neet_pyq_year"], list):
            q["neet_pyq_year"] = [q["neet_pyq_year"]]
        # bloom_level default for computed templates is already set; curated is 'recall'
        q.setdefault("bloom_level", "recall")

    # --- 5. write ---------------------------------------------------------------
    with open(OUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_questions, f, indent=2, ensure_ascii=False)

    dist = {}
    for q in all_questions:
        dist[q["subject"]] = dist.get(q["subject"], 0) + 1
    diff = {}
    for q in all_questions:
        diff[q["difficulty"]] = diff.get(q["difficulty"], 0) + 1
    print(f"\nwritten: {len(all_questions)} questions -> {OUT_FILE.name}")
    print("subjects:", dist)
    print("difficulty:", diff)
    print(f"id range: NEET-9060 .. NEET-{next_id - 1}")


if __name__ == "__main__":
    main()
