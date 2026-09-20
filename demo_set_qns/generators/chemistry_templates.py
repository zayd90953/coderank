"""NEET Chemistry template generator.

Same contract as physics_templates.py:
  - parameters drawn from chemically sensible ranges,
  - every correct answer COMPUTED (molar masses parsed from real formulas,
    pH from -log10, mu from sqrt(n(n+2)), DBE from the molecular formula...),
  - distractors built from named misconceptions, checked pairwise distinct,
  - letter assignment randomised AFTER values are verified distinct.

Python 3.10+. No third-party dependencies.
"""

from __future__ import annotations

import math
import re
from typing import Callable

from common import Q, RNG, assign_letters, dedupe, remap_cwr, sig

# ---------------------------------------------------------------------------
# Real atomic masses (IUPAC standard, rounded) — the generator computes with
# these, so "molar mass" answers are derived, not asserted.
# ---------------------------------------------------------------------------
ATOMIC = {
    "H": 1.008, "He": 4.003, "Li": 6.94, "Be": 9.012, "B": 10.81, "C": 12.011,
    "N": 14.007, "O": 15.999, "F": 18.998, "Ne": 20.180, "Na": 22.990,
    "Mg": 24.305, "Al": 26.982, "Si": 28.085, "P": 30.974, "S": 32.06,
    "Cl": 35.45, "K": 39.098, "Ca": 40.078, "Ti": 47.867, "Cr": 51.996,
    "Mn": 54.938, "Fe": 55.845, "Co": 58.933, "Ni": 58.693, "Cu": 63.546,
    "Zn": 65.38, "Br": 79.904, "Ag": 107.868, "I": 126.904, "Ba": 137.327,
    "Pt": 195.084, "Au": 196.967, "Hg": 200.592, "Pb": 207.2, "Xe": 131.293,
}

_TOKEN = re.compile(r"([A-Z][a-z]?)(\d*)")
_GROUP = re.compile(r"\(([^()]*)\)(\d*)")


def parse_formula(formula: str) -> dict[str, float]:
    """Parse a plain molecular formula (supports one level of parentheses)."""
    counts: dict[str, float] = {}

    def add(tokens: str, factor: float) -> None:
        pos = 0
        while pos < len(tokens):
            m = _TOKEN.match(tokens, pos)
            if not m or m.start() != pos:
                raise ValueError(f"bad formula tokens: {tokens!r} at {pos}")
            el, num = m.group(1), m.group(2)
            counts[el] = counts.get(el, 0) + (int(num) if num else 1) * factor
            pos = m.end()

    s = formula
    while "(" in s:
        m = _GROUP.search(s)
        if not m:
            raise ValueError(f"unbalanced formula: {formula}")
        inner: dict[str, float] = {}
        save = dict(counts)
        counts.clear()
        counts.update(save)
        add(m.group(1), int(m.group(2) or 1))
        inner.update(counts)
        counts = save
        s = s[: m.start()] + s[m.end():]
        # merge inner
        for el, n in inner.items():
            counts[el] = counts.get(el, 0) + n
    add(s, 1)
    return counts


def molar_mass(formula: str) -> float:
    counts = parse_formula(formula)
    total = sum(ATOMIC[el] * n for el, n in counts.items())
    assert total > 0
    return total


def _mk(
    subject_meta: dict,
    question_text: str,
    answers: list[str],
    explanation: str,
    cwr: dict[str, str] | None,
    difficulty: str,
    bloom: str,
    pyq: list[int] | None,
) -> Q:
    options, letter, remap = assign_letters(answers)
    return {
        **subject_meta,
        "difficulty": difficulty,
        "bloom_level": bloom,
        "question_text": question_text,
        "options": options,
        "correct_option": letter,
        "explanation": explanation,
        "common_wrong_reasoning": remap_cwr(cwr, remap) if cwr else None,
        "neet_pyq_year": pyq,
        "diagram": None,
    }


def _num4(correct: float, wrongs: list[float], unit: str, digits: int = 3) -> list[str]:
    """4 distinct formatted options; collisions fixed at BOTH float and string level."""
    wrongs = dedupe(correct, wrongs)  # float-level distinctness first
    used = {f"{sig(correct, digits)} {unit}"}
    out = [f"{sig(correct, digits)} {unit}"]
    for w in wrongs:
        s = f"{sig(w, digits)} {unit}"
        tries = 0
        while s in used and tries < 50:  # rounding can merge distinct floats
            w = w * 1.75 + 0.013
            s = f"{sig(w, digits)} {unit}"
            tries += 1
        if s not in used:
            used.add(s)
            out.append(s)
        if len(out) == 4:
            break
    assert len(out) == 4, f"could not build 4 distinct options from {correct} {wrongs}"
    return out


# ---------------------------------------------------------------------------
# TEMPLATES
# ---------------------------------------------------------------------------

def t_moles_from_mass() -> Q:
    """n = m/M, M computed from the parsed formula. [NEET recurring mole concept]"""
    formula = RNG.choice(["H2O", "CO2", "CaCO3", "NaOH", "Al2(SO4)3", "(NH4)3PO4", "CuSO4", "KMnO4", "Na2CO3", "Fe2O3"])
    mass = round(RNG.uniform(2.0, 60.0), 1)
    M = molar_mass(formula)
    n = mass / M
    wrongs = [mass / M * 2, M / mass, mass * M / 1000 if abs(mass * M / 1000 - n) > 1e-9 else n / 4]
    strs = _num4(n, wrongs, "mol", 4)
    mass_str = f"{mass:g} g"
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Some Basic Concepts of Chemistry", "ncert_class": 11, "topic": "Mole Concept and Molar Mass"},
        f"The number of moles present in {mass_str} of {formula} (molar mass computed from standard atomic masses) is:",
        strs,
        f"M({formula}) = {sig(M, 4)} g/mol. n = m/M = {mass_str}/{sig(M, 4)} = {sig(n, 4)} mol. Always compute the molar mass from the formula rather than recalling it \u2014 hydration numbers and polyatomic ions are where slips happen.",
        {
            "A": "doubled the quotient (an arithmetic slip, or using 2M implicitly)",
            "C": "inverted the relation \u2014 n = m/M, not M/m",
            "D": "an invalid mass-times-mass combination",
        },
        "Easy", "application", None,
    )


def t_molarity() -> Q:
    """M = n/V(L). [NEET recurring solutions]"""
    formula = RNG.choice(["NaCl", "KOH", "Na2CO3", "H2SO4", "C6H12O6"])
    M_molar = molar_mass(formula)
    mass = round(RNG.uniform(1.0, 25.0), 2)
    vol_mL = RNG.choice([100, 250, 500, 1000, 2000])
    n = mass / M_molar
    M = n / (vol_mL / 1000)
    wrongs = [n * 2 / (vol_mL / 1000), n / vol_mL, mass / vol_mL]
    strs = _num4(M, wrongs, "M", 4)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Solutions", "ncert_class": 12, "topic": "Concentration Terms"},
        f"{mass:g} g of {formula} (M = {sig(M_molar, 4)} g/mol) is dissolved in water to make {vol_mL} mL of solution. The molarity of the solution is:",
        strs,
        f"n = {mass:g}/{sig(M_molar, 4)} = {sig(n, 4)} mol. Volume = {vol_mL} mL = {sig(vol_mL / 1000, 4)} L. M = n/V = {sig(n, 4)}/{sig(vol_mL / 1000, 4)} = {sig(M, 4)} mol/L. The classic error is forgetting mL \u2192 L.",
        {
            "A": "doubled the mole value in the arithmetic",
            "C": "divided moles by mL without converting (a 1000\u00d7 slip)",
            "D": "used grams/mL \u2014 that is density arithmetic, not molarity",
        },
        "Easy", "application", None,
    )


def t_ph_strong_acid() -> Q:
    """pH = -log10[H+]. [NEET recurring ionic equilibrium]"""
    C = round(10 ** RNG.uniform(-4, -1), 6)
    pH = -math.log10(C)
    wrongs = [14 - pH, -math.log10(C * 2), pH + 1]
    strs = _num4(pH, wrongs, "", 2)
    strs = [s.replace(" ", "") for s in strs]
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Equilibrium", "ncert_class": 11, "topic": "Ionic Equilibrium: pH"},
        f"The pH of a {sig(C, 4)} M aqueous solution of a monoprotic strong acid (HCl) at 25 \u00b0C is:",
        strs,
        f"HCl is strong: [H\u207a] = {sig(C, 4)} M. pH = \u2212log[H\u207a] = \u2212log({sig(C, 4)}) = {sig(pH, 2)}. For a strong monoprotic acid the anion concentration does not enter; for a strong base you would compute pOH first and use pH = 14 \u2212 pOH.",
        {
            "A": "computed pOH (14 \u2212 pH) \u2014 that's for bases",
            "C": "doubled the concentration before taking the log",
            "D": "an off-by-one log slip",
        },
        "Easy", "application", None,
    )


def t_ph_weak_acid() -> Q:
    """[H+] = sqrt(Ka C); pH = -log. [NEET recurring]"""
    Ka = 10 ** RNG.uniform(-6, -3)
    C = round(RNG.uniform(0.01, 0.5), 2)
    h = math.sqrt(Ka * C)
    pH = -math.log10(h)
    wrongs = [-math.log10(Ka), -math.log10(Ka * C), -math.log10(h) / 2 if abs(-math.log10(h) / 2 - pH) > 0.01 else pH + 2]
    strs = _num4(pH, wrongs, "", 2)
    strs = [s.replace(" ", "") for s in strs]
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Equilibrium", "ncert_class": 11, "topic": "Ionic Equilibrium: Weak Acids"},
        f"An aqueous solution of a weak monobasic acid (K_a = {sig(Ka, 3)}) is {sig(C, 3)} M. Its pH is approximately:",
        strs,
        f"For a weak acid, [H\u207a] \u2248 \u221a(K_a\u00b7C) = \u221a({sig(Ka, 3)} \u00d7 {sig(C, 3)}) = {sig(h, 4)} M. pH = \u2212log({sig(h, 4)}) = {sig(pH, 2)}. The approximation (x << C) is valid because K_a is small.",
        {
            "A": "reports pK_a \u2014 that is the \u2212log of K_a, valid only for [H\u207a] = K_a (1 M acid)",
            "C": "multiplied K_a and C before taking \u2212log \u2014 the square root step was skipped",
            "D": "a factor-of-2 log error",
        },
        "Medium", "application", None,
    )


def t_first_order_kinetics() -> Q:
    """First order: fraction remaining = e^(-kt); t_(1/2) = ln2/k. [NEET recurring kinetics]"""
    k = round(RNG.uniform(0.002, 0.05), 4)
    t = float(RNG.randint(30, 400))
    frac = math.exp(-k * t) * 100
    wrongs = [100 - k * t * 100, math.exp(-k * t) * 200, 50.0]  # dedupe fixes negatives/collisions
    strs = _num4(frac, wrongs, "%", 2)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Chemical Kinetics", "ncert_class": 12, "topic": "First Order Reactions"},
        f"A first-order reaction has a rate constant k = {sig(k, 4)} s\u207b\u00b9. The percentage of reactant remaining after t = {sig(t, 3)} s is:",
        strs,
        f"First order integrated law: [A] = [A]\u2080e^(\u2212kt). Fraction remaining = e^(\u2212{sig(k, 4)} \u00d7 {sig(t, 3)}) = e^(\u2212{sig(k * t, 3)}) = {sig(frac / 100, 3)} \u21d2 {sig(frac, 2)}%. The half-life ln2/k = {sig(math.log(2) / k, 3)} s gives a quick sanity check.",
        {
            "A": "used a linear decay law \u2014 first-order decay is exponential",
            "C": "doubled the exponential fraction",
            "D": "assumed exactly one half-life had elapsed",
        },
        "Medium", "application", None,
    )


def t_order_units() -> Q:
    """Identify order from k units. [NEET recurring kinetics conceptual]"""
    cases = [
        ("s\u207b\u00b9", "zeroth", "mol L\u207b\u00b9 s\u207b\u00b9"),
        ("L mol\u207b\u00b9 s\u207b\u00b9", "second", "mol L\u207b\u00b9 s\u207b\u00b9"),
        ("L\u00b2 mol\u207b\u00b2 s\u207b\u00b9", "third", "mol L\u207b\u00b9 s\u207b\u00b9"),
        ("mol L\u207b\u00b9 s\u207b\u00b9", "zeroth", "s\u207b\u00b9"),
    ]
    k_unit, order_ans, wrong_unit = RNG.choice(cases)
    order_num = {"s\u207b\u00b9": 1, "L mol\u207b\u00b9 s\u207b\u00b9": 2, "L\u00b2 mol\u207b\u00b2 s\u207b\u00b9": 3, "mol L\u207b\u00b9 s\u207b\u00b9": 0}[k_unit]
    options_map = {
        ("s\u207b\u00b9", "zeroth"): "First order",
        ("L mol\u207b\u00b9 s\u207b\u00b9", "second"): "Second order",
        ("L\u00b2 mol\u207b\u00b2 s\u207b\u00b9", "third"): "Third order",
        ("mol L\u207b\u00b9 s\u207b\u00b9", "zeroth"): "Zero order",
    }
    correct = options_map[(k_unit, order_ans)]
    wrong_opts = [o for o in ["Zero order", "First order", "Second order", "Third order"] if o != correct]
    RNG.shuffle(wrong_opts)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Chemical Kinetics", "ncert_class": 12, "topic": "Order of Reaction"},
        f"For a reaction, the rate constant has units of {k_unit}. The overall order of the reaction is:",
        [correct] + wrong_opts,
        f"For an n-th order reaction, k has units (mol L\u207b\u00b9)^(1\u2212n) s\u207b\u00b9. Units {k_unit} match n = {order_num}. "
        f"Zero order keeps concentration units (mol L\u207b\u00b9 s\u207b\u00b9); first order drops to s\u207b\u00b9; each extra order adds a L mol\u207b\u00b9.",
        {
            "B": "confused the inverse relationship \u2014 more L mol\u207b\u00b9 factors mean HIGHER order, not lower",
            "C": "mixed up zero- and first-order units",
            "D": "only the half-life (not k) is independent of concentration for first order; this is a units question",
        },
        "Medium", "recall", None,
    )


def t_electrolysis_mass() -> Q:
    """m = M I t / (n F). [NEET recurring electrochemistry]"""
    cases = [
        ("Cu", 63.546, 2, "Cu\u00b2\u207a + 2e\u207b \u2192 Cu"),
        ("Ag", 107.868, 1, "Ag\u207a + e\u207b \u2192 Ag"),
        ("Zn", 65.38, 2, "Zn\u00b2\u207a + 2e\u207b \u2192 Zn"),
        ("Al", 26.982, 3, "Al\u00b3\u207a + 3e\u207b \u2192 Al"),
    ]
    metal, M, z, half_rxn = RNG.choice(cases)
    I = round(RNG.uniform(0.2, 5.0), 1)
    t_min = RNG.randint(5, 60)
    t = t_min * 60
    F = 96500.0
    m = M * I * t / (z * F)
    wrongs = [M * I * t / F, M * z * I * t / F if abs(M * z * I * t / F - m) > 1e-6 else m / 2, M * I * t / (z * F) / 60]
    strs = _num4(m, wrongs, "g", 4)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Electrochemistry", "ncert_class": 12, "topic": "Faraday's Laws of Electrolysis"},
        f"A current of {sig(I, 3)} A is passed through a suitable electrolyte for {t_min} minutes. The mass of {metal} deposited at the cathode (half-reaction: {half_rxn}; F = 96500 C/mol) is:",
        strs,
        f"Charge passed Q = It = {sig(I, 3)} \u00d7 {t_min} \u00d7 60 = {sig(I * t, 4)} C. Moles of e\u207b = Q/F. From {half_rxn}, {z} mol e\u207b deposit 1 mol {metal}: m = MIt/(zF) = {sig(M, 5)} \u00d7 {sig(I * t, 4)}/({z} \u00d7 96500) = {sig(m, 4)} g. The valency factor z is the make-or-break term.",
        {
            "A": "ignored the electron stoichiometry (divided by F but not by {z}F)",
            "C": "multiplied by the valency instead of dividing \u2014 more electrons per ion means LESS metal per coulomb",
            "D": "forgot to convert minutes to seconds",
        },
        "Hard", "application", None,
    )


def t_gibbs_from_cell() -> Q:
    """\u0394G\u00b0 = -nFE\u00b0cell. [NEET recurring electrochemistry]"""
    cases = [(2, 1.10, "Daniell cell (Zn|Cu)"), (2, 0.34, "Cu\u00b2\u207a/Cu"), (1, 0.76, "Zn\u00b2\u207a/Zn"), (6, 1.04, "fuel-cell style n = 6")]
    n, E, label = RNG.choice(cases)
    F = 96500.0
    dG = -n * F * E / 1000  # kJ
    wrongs = [-dG, dG / n, dG / 2]  # sign flip; per-electron confusion; stray halving
    strs = _num4(dG, wrongs, "kJ/mol", 1)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Electrochemistry", "ncert_class": 12, "topic": "Electrochemical Cell and Gibbs Energy"},
        f"For a cell reaction involving {n} electrons with standard cell potential E\u00b0_cell = {sig(E, 2)} V ({label}), the standard Gibbs energy change \u0394G\u00b0 is (F = 96500 C/mol):",
        strs,
        f"\u0394G\u00b0 = \u2212nFE\u00b0 = \u2212{n} \u00d7 96500 \u00d7 {sig(E, 2)} J/mol = {sig(dG, 1)} kJ/mol. The sign is NEGATIVE for a spontaneous galvanic reaction, and \u0394G\u00b0 scales with n \u2014 that is why cell potentials can be added but \u0394G\u00b0 per electron is what compares favourability.",
        {
            "A": "flipped the sign \u2014 a working galvanic cell releases free energy (\u0394G\u00b0 < 0)",
            "C": "divided by n after already multiplying \u2014 \u0394G\u00b0 is per mole of reaction as written",
            "D": "a stray factor from unit juggling",
        },
        "Medium", "application", None,
    )


def t_oxidation_number() -> Q:
    """Oxidation number by algebraic sum = charge. [NEET recurring redox]"""
    cases = [
        ("Cr", "Cr2O7 2-", {"Cr": 2, "O": 7}, -2, 6, [3, 4, 5]),
        ("Mn", "MnO4 -", {"Mn": 1, "O": 4}, -1, 7, [2, 4, 6]),
        ("S", "H2SO4", {"H": 2, "S": 1, "O": 4}, 0, 6, [2, 4, -2]),
        ("N", "NO3 -", {"N": 1, "O": 3}, -1, 5, [2, 3, 4]),
        ("Cl", "ClO3 -", {"Cl": 1, "O": 3}, -1, 5, [1, 3, 7]),
        ("S", "S2O3 2-", {"S": 2, "O": 3}, -2, 2, [3, 4, 6]),
    ]
    el, formula_str, comp, charge, correct, wrong_vals = RNG.choice(cases)
    name_map = {
        "Cr2O7 2-": "Cr\u2082O\u2087\u00b2\u207b (dichromate)", "MnO4 -": "MnO\u2084\u207b (permanganate)",
        "H2SO4": "H\u2082SO\u2084", "NO3 -": "NO\u2083\u207b (nitrate)", "ClO3 -": "ClO\u2083\u207b (chlorate)",
        "S2O3 2-": "S\u2082O\u2083\u00b2\u207b (thiosulfate)",
    }
    # verify by computation: sum of ox numbers = charge (O = -2, H = +1)
    o_total = comp.get("O", 0) * (-2)
    h_total = comp.get("H", 0) * (+1)
    n_el = comp[el]
    calc = (charge - o_total - h_total) / n_el
    assert abs(calc - correct) < 1e-9, f"ox-num mismatch {formula_str}: {calc} vs {correct}"
    opts = [f"+{correct}"] + [f"+{w}" for w in wrong_vals if w != correct][:3]
    if len(opts) < 4:
        opts.append(f"{correct - 1}")
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Redox Reactions", "ncert_class": 11, "topic": "Oxidation Number"},
        f"The oxidation number of {el} in {name_map[formula_str]} is:",
        opts[:4],
        f"Sum of oxidation numbers = total charge. Oxygen is \u22122 each ({comp.get('O', 0)} \u00d7 \u22122 = {o_total})"
        + (f", hydrogen is +1 each ({h_total:+d})" if "H" in comp else "")
        + f". Let {el} = x: {n_el}x {o_total:+d} {h_total:+d} = {charge} \u21d2 x = {correct:+d}.",
        {
            "B": "a common slip is forgetting that the sum must equal the ION charge, not zero",
            "C": "miscounted the number of {el} atoms per formula unit",
            "D": "applied O = \u22121 instead of \u22122 (peroxide exception misused here)",
        },
        "Easy", "application", None,
    )


def t_hybridisation() -> Q:
    """sp^n from steric number = sigma bonds + lone pairs. [NEET recurring bonding]"""
    cases = [
        ("SF\u2086", 6, 0, "sp\u00b3d\u00b2", "octahedral"),
        ("PCl\u2085", 5, 0, "sp\u00b3d", "trigonal bipyramidal"),
        ("BF\u2083", 3, 0, "sp\u00b2", "trigonal planar"),
        ("CH\u2084", 4, 0, "sp\u00b3", "tetrahedral"),
        ("NH\u2083", 3, 1, "sp\u00b3", "trigonal pyramidal"),
        ("H\u2082O", 2, 2, "sp\u00b3", "bent (V-shaped)"),
        ("XeF\u2084", 4, 2, "sp\u00b3d\u00b2", "square planar"),
        ("SF\u2084", 4, 1, "sp\u00b3d", "see-saw"),
        ("BeCl\u2082", 2, 0, "sp", "linear"),
        ("ClF\u2083", 3, 2, "sp\u00b3d", "T-shaped"),
    ]
    mol, sigma, lp, hyb, shape = RNG.choice(cases)
    ster = sigma + lp
    wrongs_set = {"sp", "sp\u00b2", "sp\u00b3", "sp\u00b3d", "sp\u00b3d\u00b2"} - {hyb}
    wrongs = sorted(wrongs_set)[:3]
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Chemical Bonding and Molecular Structure", "ncert_class": 11, "topic": "Hybridisation and VSEPR"},
        f"The hybridisation of the central atom in {mol} is:",
        [hyb] + wrongs,
        f"Steric number = \u03c3 bonds + lone pairs = {sigma} + {lp} = {ster}, which corresponds to {hyb} with a {shape} geometry. Lone pairs count toward hybridisation but change the SHAPE away from the ideal geometry.",
        {
            "B": "counted only the \u03c3 bonds and ignored lone pairs on the central atom",
            "C": "mis-assigned the steric number \u2192 hybridisation mapping (2=sp, 3=sp\u00b2, 4=sp\u00b3, 5=sp\u00b3d, 6=sp\u00b3d\u00b2)",
            "D": "an off-by-one steric count",
        },
        "Easy", "application", None,
    )


def t_magnetic_moment() -> Q:
    """\u03bc = \u221a(n(n+2)) BM with high/low spin decision. [NEET recurring coordination]"""
    cases = [
        # (ion, d-count, ligand, strong?, unpaired, ox label)
        ("Fe\u00b3\u207a", 5, "H\u2082O (weak field)", True, 5, "d\u2075 high spin"),
        ("Fe\u00b3\u207a", 5, "CN\u207b (strong field)", False, 1, "d\u2075 low spin"),
        ("Fe\u00b2\u207a", 6, "H\u2082O (weak field)", True, 4, "d\u2076 high spin"),
        ("Fe\u00b2\u207a", 6, "CN\u207b (strong field)", False, 0, "d\u2076 low spin"),
        ("Co\u00b3\u207a", 6, "NH\u2083 (strong field)", False, 0, "d\u2076 low spin"),
        ("Co\u00b2\u207a", 7, "H\u2082O (weak field)", True, 3, "d\u2077 high spin"),
        ("Mn\u00b2\u207a", 5, "H\u2082O (weak field)", True, 5, "d\u2075 high spin"),
        ("Cr\u00b3\u207a", 3, "H\u2082O (weak field)", True, 3, "d\u00b3 (field-independent)"),
        ("Ni\u00b2\u207a", 8, "H\u2082O (weak field)", True, 2, "d\u2078 high spin"),
        ("Cu\u00b2\u207a", 9, "H\u2082O (weak field)", True, 1, "d\u2079"),
    ]
    ion, d_count, ligand, weak, unpaired, note = RNG.choice(cases)
    mu = math.sqrt(unpaired * (unpaired + 2))
    wrongs = [math.sqrt((unpaired + 1) * (unpaired + 3)), float(unpaired), mu / 2]
    strs = _num4(mu, wrongs, "BM", 2)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Coordination Compounds", "ncert_class": 12, "topic": "Bonding and Magnetic Properties"},
        f"The spin-only magnetic moment of the complex ion [{ion}] with {ligand} ligands is (d-electron count: {d_count}):",
        strs,
        f"{note}: unpaired electrons n = {unpaired} (fill the d orbitals by Hund's rule; strong-field ligands pair electrons in an octahedral field, weak-field leave them unpaired). Spin-only moment \u03bc = \u221a(n(n+2)) = \u221a({unpaired} \u00d7 {unpaired + 2}) = {sig(mu, 2)} BM.",
        {
            "A": "used (n+1) unpaired electrons \u2014 a counting slip in the d configuration",
            "C": "reported the raw unpaired count, not the spin-only formula",
            "D": "a stray factor-of-two",
        },
        "Hard", "application", None,
    )


def t_degree_unsaturation() -> Q:
    """DBE = C - H/2 + N/2 + 1 (oxygen ignored). [NEET recurring organic basics]"""
    cases = [
        ("C4H6", 2), ("C6H6", 4), ("C3H6O", 1), ("C5H5N", 4), ("C2H2", 2),
        ("C7H8", 4), ("C3H3N", 3), ("C4H4O2", 3), ("C2H4O2", 1),
        ("C6H12O6", 1), ("C5H10", 1), ("C6H7N", 4),
    ]
    formula_raw, dbe = RNG.choice(cases)
    # O must be part of the pattern (fullmatch consumes the whole string) but is ignored in the count
    m = re.fullmatch(r"C(\d+)H(\d+)(?:N(\d*))?(?:O(\d*))?", formula_raw)
    assert m, formula_raw
    C = int(m.group(1)); H = int(m.group(2))
    # "N" with no trailing digits means ONE nitrogen, not zero
    N = int(m.group(3)) if m.group(3) else (1 if "N" in formula_raw else 0)
    calc = C - H / 2 + N / 2 + 1
    assert abs(calc - dbe) < 1e-9, f"DBE mismatch for {formula_raw}: {calc}"
    opts = [str(dbe), str(dbe + 1), str(dbe - 1), str(dbe + 2)]
    assert len(set(opts)) == 4
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Organic Chemistry: Some Basic Principles and Techniques", "ncert_class": 11, "topic": "Degree of Unsaturation"},
        f"The degree of unsaturation (double bond equivalents) of the compound with molecular formula {formula_raw} is:",
        opts,
        f"DBE = C \u2212 H/2 + N/2 + 1 = {C} \u2212 {H}/2 + {N}/2 + 1 = {dbe:g}. Oxygen is IGNORED in the count, each ring or \u03c0 bond adds one unit, and the +1 comes from the carbon skeleton itself. For an acyclic saturated compound the DBE is 0.",
        {
            "B": "an off-by-one \u2014 usually forgetting the +1 for the carbon skeleton itself",
            "C": "treated halogens as if they add (they subtract, like extra hydrogens)",
            "D": "sign error in the formula",
        },
        "Medium", "application", None,
    )


def t_freezing_depression() -> Q:
    """\u0394Tf = Kf m (and i for dissociation). [NEET recurring solutions]"""
    solute = RNG.choice([("glucose", 1), ("NaCl", 2), ("CaCl\u2082", 3), ("KCl", 2)])
    name, i = solute
    m = round(RNG.uniform(0.1, 3.0), 2)
    Kf = RNG.choice([1.86, 5.12])  # water / benzene
    solvent = "water" if Kf == 1.86 else "benzene"
    T0 = 0.0 if solvent == "water" else 5.5
    dT = i * Kf * m
    Tf = T0 - dT
    if i > 1:
        wrongs = [T0 - Kf * m, T0 - i * Kf * m / 2, T0 + dT]  # ignored i; halved; wrong sign
    else:
        wrongs = [T0 - Kf * m / 2, T0 + dT, T0 - 2 * Kf * m]  # halved; wrong sign; doubled
    strs = _num4(Tf, wrongs, "\u00b0C", 3)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Solutions", "ncert_class": 12, "topic": "Colligative Properties"},
        f"A {sig(m, 3)} molal solution of {name} in {solvent} (K_f = {sig(Kf, 3)} K kg mol\u207b\u00b9) is prepared. {name} dissociates completely with van't Hoff factor i = {i}. The freezing point of the solution is:",
        strs,
        f"\u0394T_f = i\u00b7K_f\u00b7m = {i} \u00d7 {sig(Kf, 3)} \u00d7 {sig(m, 3)} = {sig(dT, 3)} \u00b0C. The solution freezes {sig(dT, 3)} \u00b0C BELOW the pure solvent ({sig(T0, 3)} \u00b0C), i.e. at {sig(Tf, 3)} \u00b0C. Dissociation multiplies the particle count \u2014 that is the whole van't Hoff factor effect.",
        {
            "A": "ignored the van't Hoff factor \u2014 dissociation multiplies the particle count",
            "C": "halved the correctly-computed depression",
            "D": "added rather than subtracted \u2014 dissolution always LOWERS the freezing point",
        },
        "Medium", "application", None,
    )


def t_osmotic_pressure() -> Q:
    """\u03c0 = MRT. [NEET recurring solutions]"""
    M = round(RNG.uniform(0.05, 1.5), 2)
    T_K = float(RNG.randint(273, 320))
    R = 0.0821
    pi = M * R * T_K
    wrongs = [M * R * T_K / 2, M * 8.314 * T_K, M * R * (T_K - 273)]
    wrongs[1] = pi if abs(wrongs[1] - pi) < 0.01 else wrongs[1]
    strs = _num4(pi, wrongs, "atm", 3)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Solutions", "ncert_class": 12, "topic": "Colligative Properties: Osmotic Pressure"},
        f"The osmotic pressure of a {sig(M, 3)} M solution of a non-electrolyte at {sig(T_K, 3)} K is (R = 0.0821 L atm K\u207b\u00b9 mol\u207b\u00b9):",
        strs,
        f"\u03c0 = MRT = {sig(M, 3)} \u00d7 0.0821 \u00d7 {sig(T_K, 3)} = {sig(pi, 3)} atm. Use R consistent with the pressure unit wanted (0.0821 for atm), and temperature in KELVIN.",
        {
            "A": "an arbitrary halving",
            "C": "used R = 8.314 (SI) with an atm answer \u2014 unit mismatch",
            "D": "plugged Celsius temperature: \u03c0 collapses near 0 \u00b0C, which is unphysical here",
        },
        "Easy", "application", None,
    )


def t_ideal_gas_law() -> Q:
    """PV = nRT solve for the missing variable. [NEET recurring states of matter]"""
    mode = RNG.choice(["V", "P", "n"])
    R = 0.0821
    if mode == "V":
        n = round(RNG.uniform(0.1, 3.0), 2); T = float(RNG.randint(250, 400)); P = round(RNG.uniform(0.5, 5.0), 2)
        V = n * R * T / P
        qt = f"What volume is occupied by {sig(n, 3)} mol of an ideal gas at {sig(T, 3)} K and {sig(P, 3)} atm? (R = 0.0821 L atm K\u207b\u00b9 mol\u207b\u00b9)"
        ans = V
        wrongs = [V * P, V / T * 273, n * R * T / P / 2]
        unit = "L"
    elif mode == "P":
        n = round(RNG.uniform(0.1, 3.0), 2); T = float(RNG.randint(250, 400)); V = round(RNG.uniform(2.0, 40.0), 1)
        P = n * R * T / V
        qt = f"{sig(n, 3)} mol of an ideal gas occupies {sig(V, 3)} L at {sig(T, 3)} K. Its pressure is (R = 0.0821 L atm K\u207b\u00b9 mol\u207b\u00b9):"
        ans = P
        wrongs = [n * R * T * V, P / 2 if P / 2 != n * R * T * V else P * 2, n * R * 273 / V]
        unit = "atm"
    else:
        P = round(RNG.uniform(0.5, 5.0), 2); T = float(RNG.randint(250, 400)); V = round(RNG.uniform(2.0, 40.0), 1)
        n = P * V / (R * T)
        qt = f"The number of moles of an ideal gas in {sig(V, 3)} L at {sig(T, 3)} K and {sig(P, 3)} atm is (R = 0.0821 L atm K\u207b\u00b9 mol\u207b\u00b9):"
        ans = n
        wrongs = [P * V * R * T, n / 2 if n / 2 > 0.05 else n * 2, P * V / (R * 273)]
        unit = "mol"
    strs = _num4(ans, wrongs, unit, 3)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "States of Matter", "ncert_class": 11, "topic": "Ideal Gas Equation"},
        qt, strs,
        f"PV = nRT solved for the unknown: {sig(ans, 3)} {unit}. Keep R matched to the units (0.0821 for L\u00b7atm) and T in kelvin \u2014 those two conventions resolve most ideal-gas slips.",
        {
            "A": "an algebra inversion or unit slip in rearranging PV = nRT",
            "C": "used 0 \u00b0C = 273 K regardless of the stated temperature",
            "D": "an arithmetic slip with a factor of two",
        },
        "Medium", "application", None,
    )


def t_kc_manipulation() -> Q:
    """K for reversed/doubled/halved equations. [NEET recurring equilibrium]"""
    mode = RNG.choice(["reverse", "double", "halve"])
    K = RNG.choice([4.0, 9.0, 16.0, 25.0, 2.0])
    if mode == "reverse":
        ans, txt = 1 / K, "the equation is REVERSED"
        rule = "K' = 1/K"
        val = 1 / K
    elif mode == "double":
        ans, txt = K * K, "the equation is multiplied by 2"
        rule = "K' = K\u00b2"
        val = K * K
    else:
        ans, txt = math.sqrt(K), "the equation is divided by 2"
        rule = "K' = \u221aK"
        val = math.sqrt(K)
    wrongs = [K * 2, K / 2, 1 / val if abs(1 / val - val) > 1e-9 else K + 3]
    strs = _num4(val, wrongs, "", 4)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Equilibrium", "ncert_class": 11, "topic": "Equilibrium Constant Manipulation"},
        f"For a gaseous reaction, K_c = {sig(K, 3)} at a given temperature. If {txt}, the new equilibrium constant is:",
        strs,
        f"Equilibrium constants follow the stoichiometry: {rule} when {txt}. So K' = {sig(val, 4)}. (Reversing inverts K; multiplying the equation by m raises K to the m-th power; adding equations multiplies their K values.)",
        {
            "A": "scaled K linearly \u2014 K is a product of concentration terms, so scaling is via powers",
            "C": "an arbitrary halving",
            "D": "inverted when not required (or failed to invert when required)",
        },
        "Medium", "application", None,
    )


def t_average_atomic_mass() -> Q:
    """Weighted average of isotopes. [NEET recurring structure of atom]"""
    pairs = [((20, 80), (22, 20), "neon"), ((35, 75), (37, 25), "chlorine"),
             ((63, 70), (65, 30), "copper"), ((10, 20), (11, 80), "boron"),
             ((107, 50), (109, 50), "silver")]
    (m1, _pa), (m2, _pb), el = RNG.choice(pairs)
    p1 = RNG.randint(5, 95)
    p2 = 100 - p1
    avg = (m1 * p1 + m2 * p2) / (p1 + p2)
    wrongs = [(m1 + m2) / 2, m1 * p1 / 100 + m2, (m1 * p2 + m2 * p1) / 100]
    wrongs = [w if abs(w - avg) > 1e-9 else w + 1 for w in wrongs]
    strs = _num4(avg, wrongs, "u", 2)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Structure of Atom", "ncert_class": 11, "topic": "Atomic Mass and Isotopes"},
        f"{el.capitalize()} exists as two isotopes: mass {m1} u ({p1}% abundance) and mass {m2} u ({p2}% abundance). Its average atomic mass is:",
        strs,
        f"Weighted average = ({m1}\u00d7{p1} + {m2}\u00d7{p2})/100 = {sig(avg, 2)} u. The average always sits CLOSER to the more abundant isotope \u2014 a quick sanity check against the midpoint trap.",
        {
            "A": "the simple midpoint \u2014 valid only for a 50:50 mix",
            "C": "swapped the abundances between the masses",
            "D": "an inconsistent weighting",
        },
        "Easy", "application", None,
    )


def t_solid_state_density() -> Q:
    """d = Z M / (a\u00b3 N_A). [NEET recurring solid state]"""
    cases = [(4, "fcc"), (2, "bcc"), (1, "simple cubic")]
    Z, lattice = RNG.choice(cases)
    M = RNG.choice([27.0, 39.0, 55.8, 58.5, 63.5, 65.4, 108.0])
    a_pm = RNG.randint(280, 520)
    a_cm = a_pm * 1e-10
    NA = 6.022e23
    d = Z * M / (a_cm ** 3 * NA)
    wrongs = [Z * M / (a_cm ** 3 * NA) * 2, M / (a_cm ** 3 * NA), Z * M / (a_cm ** 2 * NA)]
    wrongs = [w if abs(w - d) > 1e-9 else w * 3 for w in wrongs]
    strs = _num4(d, wrongs, "g/cm\u00b3", 3)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Solid State", "ncert_class": 12, "topic": "Density of Unit Cell"},
        f"A metal (molar mass {sig(M, 3)} g/mol) crystallises in a {lattice} lattice with unit cell edge {a_pm} pm. The density of the metal is (N_A = 6.022 \u00d7 10\u00b2\u00b3):",
        strs,
        f"Z for {lattice} = {Z}. a = {a_pm} pm = {a_pm} \u00d7 10\u207b\u00b9\u2070 cm. d = ZM/(a\u00b3N_A) = {Z} \u00d7 {sig(M, 3)}/(({sig(a_cm, 4)})\u00b3 \u00d7 6.022\u00d710\u00b2\u00b3) = {sig(d, 3)} g/cm\u00b3. The three unit conversions (pm\u2192cm, per-cell\u2192per-mole) are the entire difficulty.",
        {
            "A": "a factor-of-2 slip (wrong Z or edge counting)",
            "C": "divided by N_A but forgot to multiply by Z",
            "D": "used a\u00b2 instead of a\u00b3 \u2014 density needs the CELL VOLUME",
        },
        "Hard", "application", None,
    )


def t_buffer_ph() -> Q:
    """Henderson-Hasselbalch: pH = pKa + log([A-]/[HA]). [NEET recurring ionic eq]"""
    pKa = RNG.choice([4.74, 4.76, 7.2, 9.25])
    ratio = round(10 ** RNG.uniform(-1.5, 1.5), 3)
    pH = pKa + math.log10(ratio)
    wrongs = [pKa - math.log10(ratio), pKa, pH + 1 if abs(pH + 1 - (pKa - math.log10(ratio))) > 0.01 else pH - 1]
    strs = _num4(pH, wrongs, "", 2)
    strs = [s.strip() for s in strs]
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Equilibrium", "ncert_class": 11, "topic": "Buffers"},
        f"A buffer contains a weak acid and its conjugate base with [conjugate base]/[acid] = {sig(ratio, 3)}. Given pK_a = {sig(pKa, 2)}, the pH of the buffer is:",
        strs,
        f"Henderson\u2013Hasselbalch: pH = pK_a + log([base]/[acid]) = {sig(pKa, 2)} + log({sig(ratio, 3)}) = {sig(pKa, 2)} + {sig(math.log10(ratio), 2)} = {sig(pH, 2)}. When the ratio is 1, pH = pK_a exactly \u2014 the defining point of a buffer's maximum capacity.",
        {
            "A": "subtracted the log term \u2014 the base goes in the NUMERATOR of the ratio",
            "C": "reported pK_a, valid only for an equimolar buffer",
            "D": "an off-by-one on the log",
        },
        "Medium", "application", None,
    )


def t_iodoform_test() -> Q:
    """Which compound gives iodoform test \u2014 needs CH3CO- or CH3CH(OH)-. [NEET recurring carbonyl]"""
    cases = [
        ("Acetone", True, "has the CH\u2083CO\u2013 group"),
        ("Ethanol", True, "is oxidised to acetaldehyde (CH\u2083CHO) first, which has CH\u2083CO\u2013"),
        ("2-butanol", True, "contains CH\u2083CH(OH)\u2013, oxidised to a methyl ketone"),
        ("Propanal", False, "lacks the methyl ketone/CH\u2083CH(OH)\u2013 pattern (CH\u2083CH\u2082CHO)"),
        ("Methanol", False, "no carbonyl and no oxidisable methyl-carbinol pattern"),
        ("Benzaldehyde", False, "no \u03b1-methyl group \u2014 C\u2086H\u2085CHO has no CH\u2083CO\u2013"),
        ("3-pentanone", False, "a ketone but NOT a methyl ketone ((CH\u2083CH\u2082)\u2082CO)"),
        ("Acetophenone", True, "is a methyl ketone (C\u2086H\u2085COCH\u2083)"),
    ]
    name, positive, why = RNG.choice(cases)
    positives = [c[0] for c in cases if c[1] and c[0] != name]
    negatives = [c[0] for c in cases if not c[1] and c[0] != name]
    answer = "Yes, it gives a positive iodoform test" if positive else "No, it gives a negative iodoform test"
    wrongs = [
        ("Yes, it gives a positive iodoform test" if not positive else "No, it gives a negative iodoform test"),
        f"Only aldehydes respond, and only if aromatic ({negatives[0] if negatives else 'benzaldehyde'}-type behaviour)",
        "Only primary alcohols respond",
    ]
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Aldehydes, Ketones and Carboxylic Acids", "ncert_class": 12, "topic": "Identification Tests"},
        f"Is {name} expected to give a positive iodoform test (yellow CHI\u2083 precipitate with I\u2082/NaOH)?",
        [answer] + wrongs[:3],
        f"The iodoform test needs a CH\u2083CO\u2013 group (methyl ketone) or a CH\u2083CH(OH)\u2013 group (oxidisable to one). {name} "
        f"{'qualifies: it ' + why if positive else 'does not qualify: it ' + why}. The test is specific to that structural motif, not to aldehydes or ketones in general.",
        {
            "B": "over-generalised \u2014 the test detects the CH\u2083CO\u2013 motif, not a compound class",
            "C": "restricted the test to aromatic aldehydes \u2014 benzaldehyde in fact gives a NEGATIVE iodoform test",
            "D": "restricted to primary alcohols \u2014 ethanol (primary) is positive, but methyl ketones are too",
        },
        "Medium", "analysis", None,
    )


def t_limiting_reagent() -> Q:
    """Limiting reagent and product moles. [NEET recurring mole concept]"""
    cases = [
        ("N\u2082", "H\u2082", "NH\u2083", (1, 3, 2), (2.0, 3.0)),
        ("H\u2082", "O\u2082", "H\u2082O", (2, 1, 2), (3.0, 2.0)),
        ("C", "O\u2082", "CO\u2082", (1, 1, 1), (2.5, 2.0)),
        ("HCl", "NaOH", "NaCl", (1, 1, 1), (1.5, 2.0)),
    ]
    r1, r2, prod, coeffs, avail = RNG.choice(cases)
    a1, a2 = avail
    c1, c2, cp = coeffs
    lim1 = a1 / c1
    lim2 = a2 / c2
    limiting = r1 if lim1 <= lim2 else r2
    extent = min(lim1, lim2)
    n_prod = extent * cp
    other = r2 if limiting == r1 else r1
    wrongs = [max(lim1, lim2) * cp, n_prod / 2, a1 + a2 if abs(a1 + a2 - n_prod) > 0.5 else n_prod * 2]
    strs = _num4(n_prod, wrongs, "mol", 3)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Some Basic Concepts of Chemistry", "ncert_class": 11, "topic": "Stoichiometry and Limiting Reagent"},
        f"{sig(a1, 3)} mol of {r1} reacts with {sig(a2, 3)} mol of {r2} according to the balanced equation using coefficients ({c1} {r1} : {c2} {r2} : {cp} {prod}). The maximum moles of {prod} formed are:",
        strs,
        f"Extent from each reactant: {r1} allows {sig(a1, 3)}/{c1} = {sig(lim1, 3)} 'rounds'; {r2} allows {sig(a2, 3)}/{c2} = {sig(lim2, 3)} rounds. {limiting} runs out first, so extent = {sig(extent, 3)} and product = {cp} \u00d7 {sig(extent, 3)} = {sig(n_prod, 3)} mol. Some {other} remains unreacted.",
        {
            "A": "used the reactant in EXCESS to size the extent",
            "C": "forgot to scale by the product coefficient {cp}".format(cp=cp),
            "D": "added the reactant moles together",
        },
        "Medium", "application", None,
    )


def t_percent_yield() -> Q:
    """% yield = actual/theoretical x 100. [NEET recurring]"""
    theoretical = round(RNG.uniform(2.0, 15.0), 1)
    pct = RNG.randint(50, 98)
    actual = theoretical * pct / 100
    wrongs = [theoretical, theoretical * pct / 200, actual / 2]  # unscaled; halved pct; halved product
    strs = _num4(actual, wrongs, "g", 3)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Some Basic Concepts of Chemistry", "ncert_class": 11, "topic": "Stoichiometry: Yield"},
        f"A reaction has a theoretical yield of {sig(theoretical, 3)} g. If the percentage yield is {pct}%, the actual mass of product obtained is:",
        strs,
        f"Actual = theoretical \u00d7 (pct/100) = {sig(theoretical, 3)} \u00d7 {pct}/100 = {sig(actual, 3)} g. Percentage yield is never above 100 for a straightforward synthesis; values near it suggest the product was wet or impure.",
        {
            "A": "inverted the ratio (that would exceed 100%)",
            "C": "halved the percentage",
            "D": "reported the theoretical yield, not the scaled one",
        },
        "Easy", "application", None,
    )


def t_bohr_energy_chem() -> Q:
    """E_n = -13.6/n\u00b2 eV and ionisation context (structure of atom). [NEET recurring]"""
    n1 = RNG.choice([1, 2, 3])
    n2 = n1 + RNG.choice([1, 2])
    dE = 13.6 * (1 / (n1 ** 2) - 1 / (n2 ** 2))
    qt = f"The energy emitted (eV) when an H-atom electron falls from n = {n2} to n = {n1} is (ground-state energy \u221213.6 eV):"
    wrongs = [13.6 / n2 ** 2 - 13.6 / n1 ** 2, 13.6 / (n2 ** 2), 13.6 * (1 / n1 - 1 / n2)]
    strs = _num4(dE, wrongs, "eV", 3)
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Structure of Atom", "ncert_class": 11, "topic": "Bohr Model and Line Spectra"},
        qt, strs,
        f"E_n = \u221213.6/n\u00b2 eV. \u0394E = 13.6(1/{n1}\u00b2 \u2212 1/{n2}\u00b2) = 13.6({sig(1 / n1 ** 2, 4)} \u2212 {sig(1 / n2 ** 2, 4)}) = {sig(dE, 3)} eV, emitted as one photon (E = h\u03bd). Larger n means higher (less negative) energy \u2014 falls RELEASE energy.",
        {
            "A": "subtracted in the wrong order (that would be negative \u2014 absorption sign convention)",
            "C": "reported the final level's energy above zero",
            "D": "used 1/n instead of 1/n\u00b2",
        },
        "Medium", "application", None,
    )


def t_electronic_config_unpaired() -> Q:
    """Unpaired electrons in atoms/ions (Hund's rule). [NEET recurring]"""
    cases = [
        ("Cr (Z = 24)", [3, 5, 1], "3d\u2075 4s\u00b9 (half-filled stability)", 6),
        ("Fe\u00b3\u207a", [3, 5, 0], "3d\u2075", 5),
        ("Cu (Z = 29)", [3, 10, 1], "3d\u00b9\u2070 4s\u00b9", 1),
        ("Mn\u00b2\u207a", [3, 5, 0], "3d\u2075", 5),
        ("Ni\u00b2\u207a", [3, 8, 0], "3d\u2078", 2),
        ("O atom (Z = 8)", [2, 4, 0], "2p\u2074", 2),
        ("N atom (Z = 7)", [2, 3, 0], "2p\u00b3", 3),
        ("Cl atom (Z = 17)", [3, 5, 0], "3p\u2075", 1),
    ]
    species, (_n, _l, _cfg), config_note, unpaired = RNG.choice(cases)
    mu = math.sqrt(unpaired * (unpaired + 2))
    wrong_counts = dedupe(float(unpaired), [unpaired + 1.0, unpaired - 1.0, unpaired + 2.0, unpaired * 2.0])
    wrong_counts = [int(round(w)) for w in wrong_counts]
    opts = [f"{unpaired} unpaired (\u03bc = {sig(mu, 2)} BM)"] + [
        f"{w} unpaired (\u03bc = {sig(math.sqrt(w * (w + 2)), 2)} BM)" for w in wrong_counts
    ]
    assert len(set(opts)) == 4
    return _mk(
        {"id": "", "subject": "Chemistry", "chapter": "Structure of Atom", "ncert_class": 11, "topic": "Electronic Configuration and Hund's Rule"},
        f"The number of unpaired electrons (and spin-only moment) in {species} is:",
        opts,
        f"{species}: configuration {config_note}. Fill orbitals singly first (Hund's rule), then pair. Unpaired count = {unpaired}, so \u03bc = \u221a(n(n+2)) = \u221a({unpaired}({unpaired}+2)) = {sig(mu, 2)} BM."
        + (" Exceptional configurations (Cr, Cu) follow half/fully-filled d-subshell stability." if "Cr" in species or "Cu" in species else ""),
        {
            "B": "a counting slip in the d/p subshell occupancy",
            "C": "paired electrons too early (violating Hund's rule)",
            "D": "double-counted every unpaired electron",
        },
        "Medium", "application", None,
    )


TEMPLATES: list[Callable[[], Q]] = [
    t_moles_from_mass, t_molarity, t_ph_strong_acid, t_ph_weak_acid,
    t_first_order_kinetics, t_order_units, t_electrolysis_mass, t_gibbs_from_cell,
    t_oxidation_number, t_hybridisation, t_magnetic_moment, t_degree_unsaturation,
    t_freezing_depression, t_osmotic_pressure, t_ideal_gas_law, t_kc_manipulation,
    t_average_atomic_mass, t_solid_state_density, t_buffer_ph, t_iodoform_test,
    t_limiting_reagent, t_percent_yield, t_bohr_energy_chem, t_electronic_config_unpaired,
]


def generate(count: int, start_id: int = 9300) -> list[Q]:
    out: list[Q] = []
    per = [count // len(TEMPLATES)] * len(TEMPLATES)
    for i in range(count % len(TEMPLATES)):
        per[i] += 1
    next_id = start_id
    while any(p > 0 for p in per):
        idx = RNG.randrange(len(TEMPLATES))
        if per[idx] <= 0:
            continue
        per[idx] -= 1
        q = TEMPLATES[idx]()
        q["id"] = f"NEET-{next_id}"
        next_id += 1
        out.append(q)
    return out


def selftest() -> None:
    failures = 0
    for t in TEMPLATES:
        for _ in range(300):
            try:
                q = t()
                assert q["correct_option"] in "ABCD"
                assert len(set(q["options"])) == 4
                assert len(q["explanation"]) >= 40
                assert all(len(o) > 0 for o in q["options"])
            except AssertionError as e:
                failures += 1
                print(f"SELFTEST FAIL [{t.__name__}]: {e}")
    print(f"selftest: {len(TEMPLATES)} templates x 300 runs, {failures} failures")


if __name__ == "__main__":
    selftest()
