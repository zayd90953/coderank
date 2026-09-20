"""Shared helpers for the demo_set_qns question generators.

Design rules enforced here:
  - ONE seeded RNG => regenerated banks are byte-for-byte reproducible/diffable.
  - Option letters are assigned by shuffling COMPUTED answer values, so a
    question's correctness never depends on which letter the right answer
    happens to land on.
  - Distractors must be pairwise distinct; helpers assert this loudly.
  - Everything is plain text (no tables/diagrams) per QUESTION_SCHEMA.md.
"""

from __future__ import annotations

import math
import random
import sys
from typing import Any, Sequence

# Windows consoles default to cp1252; generated text contains unicode symbols.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

Q = dict[str, Any]

# Single shared, reproducible RNG (date-seeded).
RNG = random.Random(20260913)

# Two-column factual data written as "left|right" strings; rendered as
# sentences, never tables (schema questions must be plain text).
Series = list[str]

_LETTERS = "ABCD"


def u(x: float) -> str:
    """Compact float formatting: 4.0 -> '4', 0.5 -> '0.5'."""
    return f"{x:g}"


def sig(x: float, digits: int = 3) -> str:
    """Format to `digits` significant figures, plain decimal (never exponent)."""
    if x == 0:
        return "0"
    exp = math.floor(math.log10(abs(x)))
    dec = max(0, digits - 1 - exp)
    val = round(x, dec)
    s = f"{val:.{dec}f}" if dec else f"{val:.0f}"
    if "." in s:
        s = s.rstrip("0").rstrip(".")
    return s


def fmt_sig(x: float, digits: int = 3) -> str:
    """Alias kept for readability at call sites."""
    return sig(x, digits)


def pick(seq: Sequence[str]) -> str:
    """RNG.choice over a plain sequence."""
    return RNG.choice(list(seq))


def uniq_ok(values: Sequence[str]) -> bool:
    """Assert options are pairwise distinct after whitespace-stripping."""
    stripped = [v.strip() for v in values]
    assert len(stripped) == len(set(stripped)), f"duplicate options: {stripped}"
    return True


def assign_letters(answers: Sequence[str]) -> tuple[list[str], str, dict[str, str]]:
    """Shuffle [correct, wrong1, wrong2, wrong3] into positions A-D.

    Returns (options, correct_letter, remap) where remap translates the
    VALUE-INDEX letters ('B','C','D' = the wrongs in input order) to their
    FINAL letters, so misconception dictionaries can be relabelled safely.
    """
    assert len(answers) == 4, f"need exactly 4 answers, got {len(answers)}"
    uniq_ok(answers)
    order = RNG.sample(range(4), 4)  # order[value_idx] = final position
    options: list[str | None] = [None] * 4
    correct_letter = ""
    remap: dict[str, str] = {}
    for value_idx, pos in enumerate(order):
        options[pos] = answers[value_idx]
        if value_idx == 0:
            correct_letter = _LETTERS[pos]
        else:
            remap[_LETTERS[value_idx]] = _LETTERS[pos]
    assert all(o is not None for o in options)
    return options, correct_letter, remap  # type: ignore[return-value]


def remap_cwr(cwr: dict[str, str], remap: dict[str, str]) -> dict[str, str]:
    """Relabel misconception keys from value-index letters to final letters."""
    return {remap[k]: v for k, v in cwr.items() if k in remap}


def dedupe(correct: float, candidates: list[float], k: int = 3) -> list[float]:
    """Return k wrong answers distinct from each other and from `correct`.

    Misconception values are used as-is when they don't collide. When a
    parameter choice makes two misconception formulas agree (e.g. the
    'forgot valency z' distractor equals the correct answer for z = 1), the
    colliding value is replaced by a deterministic nudge so generation never
    dies on an assert.
    """
    wrongs: list[float] = []
    tol = max(abs(correct) * 0.005, 1e-9)
    for c in candidates:
        tries = 0
        while (abs(c - correct) <= tol or any(abs(c - w) <= tol for w in wrongs)) and tries < 50:
            c = c * 1.75 + abs(correct) * 0.017 + 0.013
            tries += 1
        if len(wrongs) < k and abs(c - correct) > tol and all(abs(c - w) > tol for w in wrongs):
            wrongs.append(c)
        if len(wrongs) == k:
            break
    assert len(wrongs) == k, f"dedupe could not find {k} distinct wrongs for {correct}"
    return wrongs
