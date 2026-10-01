#!/usr/bin/env python3
"""Merge the dormant demo bank (demo_set_qns/) into the shipped question bank.

The bank has switched to the QUESTION_SCHEMA.md shape, and every demo ID
(`NEET-15000+`) cannot collide with the main bank (`NEET-9060…14999`
currently shipped).

What this script does:
  1. Loads the main bank + the three demo batches.
  2. Verifies: no ID collisions, every question carries the required key set,
     4 options, a valid correct answer, a known difficulty, and every
     `diagram` reference exists as a file in demo_set_qns/diagrams/.
  3. Appends the demo questions to the main bank (idempotent: skips IDs that
     are already present) and writes the merged bank back to
     lib/features/practice/data/questions.json.
  4. Copies the 220 diagram SVGs referenced by the new questions into the
     bundled assets folder assets/practice/diagrams/.
"""

import json
import os
import shutil

MAIN_BANK = "lib/features/practice/data/questions.json"
DEMO_FILES = [
    "demo_set_qns/demo_questions.json",
    "demo_set_qns/demo_questions_batch2.json",
    "demo_set_qns/demo_questions_generated.json",
]
DIAGRAM_DIR = "demo_set_qns/diagrams"
ASSETS_DIR = "assets/practice/diagrams"

REQUIRED = {
    "id", "subject", "chapter", "topic", "bloom_level", "difficulty",
    "question_text", "options", "correct_option", "explanation",
    "ncert_class",
}
DIFFICULTY = {"Easy", "Medium", "Hard"}


def load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def validate(questions, src_name, seen_ids, diag_refs):
    for idx, q in enumerate(questions):
        if not isinstance(q, dict):
            raise SystemExit(f"{src_name}[{idx}] is not an object")
        missing = REQUIRED - q.keys()
        if missing:
            raise SystemExit(f"{src_name}[{idx}] missing keys: {sorted(missing)}")
        if not (isinstance(q["options"], list) and len(q["options"]) == 4):
            raise SystemExit(f"{src_name}[{idx}] options must be 4")
        if q["correct_option"] not in ("A", "B", "C", "D"):
            raise SystemExit(f"{src_name}[{idx}] correct_option invalid")
        if q["id"] in seen_ids:
            raise SystemExit(f"{src_name}[{idx}] duplicate id {q['id']}")
        if q["subject"] not in {"Physics", "Chemistry", "Biology"}:
            raise SystemExit(f"{src_name}[{idx}] unknown subject {q['subject']}")
        if q["difficulty"] not in DIFFICULTY:
            raise SystemExit(f"{src_name}[{idx}] unknown difficulty {q['difficulty']}")
        seen_ids.add(q["id"])
        if q.get("diagram"):
            diag_refs.add(q["diagram"])
            if not os.path.exists(os.path.join(DIAGRAM_DIR, q["diagram"])):
                raise SystemExit(f"{src_name}[{idx}] diagram file missing: {q['diagram']}")


def main():
    with open(MAIN_BANK, encoding="utf-8") as fh:
        main_bank = json.load(fh)
    if not isinstance(main_bank, list):
        raise SystemExit(f"{MAIN_BANK} is not a JSON array")
    main_is_schema = "question_text" in main_bank[0]
    main_ids = {q["id"] for q in main_bank}
    print(f"main bank: {len(main_bank)} questions "
          f"({'schema' if main_is_schema else 'app'})")

    all_ids, diag_refs = set(), set()
    for path in DEMO_FILES:
        batch = load(path)
        if not isinstance(batch, list):
            raise SystemExit(f"{path} is not a JSON array")
        # validate() takes a collection; all_ids doubles as the
        # cross-batch duplicate-ID guard.
        validate(batch, path, all_ids, diag_refs)
        print(f"{path}: {len(batch)} questions ok")

    missing = diag_refs - {f for f in os.listdir(DIAGRAM_DIR)}
    if missing:
        raise SystemExit(f"Diagram files missing from {DIAGRAM_DIR}: {sorted(missing)}")

    new_count = 0
    for path in DEMO_FILES:
        for q in load(path):
            if q["id"] in main_ids:
                continue
            main_bank.append(q)
            new_count += 1

    with open(MAIN_BANK, "w", encoding="utf-8") as fh:
        json.dump(main_bank, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    os.makedirs(ASSETS_DIR, exist_ok=True)
    for ref in sorted(diag_refs):
        if os.path.exists(os.path.join(ASSETS_DIR, ref)):
            continue
        src = os.path.join(DIAGRAM_DIR, ref)
        dst = os.path.join(ASSETS_DIR, ref)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)

    print(f"merged: {new_count} new questions -> {MAIN_BANK} "
          f"({len(main_bank)} total)")
    print(f"diagram questions: {len(diag_refs)}; "
          f"SVGs copied to {ASSETS_DIR}")
    print(f"bank size now: {os.path.getsize(MAIN_BANK) / 1024 / 1024:.1f} MB")
    print(f"asset size now: {sum(os.path.getsize(os.path.join(ASSETS_DIR, f)) for f in os.listdir(ASSETS_DIR)) / 1024 / 1024:.1f} MB")


if __name__ == "__main__":
    main()
