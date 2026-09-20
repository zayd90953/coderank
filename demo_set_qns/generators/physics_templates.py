"""NEET Physics template generator.

Every template is a parameterised version of a real, frequently-repeated NEET
question archetype (archetype frequencies cross-checked against ExamSIDE's
year-wise NEET PYQ index, 2000-2026). Each template:

  1. draws random parameters from a *physically sensible* range,
  2. computes the correct answer from the actual physics formula (never
     hand-assigned), and
  3. builds each distractor from a NAMED misconception, then verifies the
     distractors are distinct and non-degenerate (selftest hook).

Answer/distractor values are always generated BEFORE option letters are
assigned, so correctness never depends on letter luck.

Python 3.10+. No third-party dependencies.
"""

from __future__ import annotations

import math
from fractions import Fraction
from typing import Callable

from common import Q, RNG, Series, dedupe, fmt_sig, pick, sig, u, uniq_ok

E = math.e
PI = math.pi


def _mk(
    subject_meta: dict,
    question_text: str,
    answers: list[str],  # [correct, w1, w2, w3] value strings
    explanation: str,
    cwr: dict[str, str] | None,
    difficulty: str,
    bloom: str,
    pyq: list[int] | None,
) -> Q:
    """Assign answer to a random letter, keep distractors on the rest."""
    assert len(answers) == 4 and len(set(answers)) == 4, f"degenerate answers: {answers}"
    order = RNG.sample(range(4), 4)  # order[i] = position of answers[i]
    options: list[str | None] = [None] * 4
    correct_letter = None
    for value_idx, pos in enumerate(order):
        options[pos] = answers[value_idx]
        if value_idx == 0:
            correct_letter = "ABCD"[pos]
    assert all(o is not None for o in options)
    cwr_final = None
    if cwr:
        # remap misconception labels: original value-index letter -> final letter
        remap = {"ABCD"[i]: "ABCD"[order[i]] for i in range(1, 4)}
        cwr_final = {remap[k]: v for k, v in cwr.items() if k in remap}
    return {
        **subject_meta,
        "difficulty": difficulty,
        "bloom_level": bloom,
        "question_text": question_text,
        "options": options,  # type: ignore[arg-type]
        "correct_option": correct_letter,
        "explanation": explanation,
        "common_wrong_reasoning": cwr_final,
        "neet_pyq_year": pyq,
        "diagram": None,
    }


# ---------------------------------------------------------------------------
# Helpers for building numeric distractor sets
# ---------------------------------------------------------------------------

def _distinct_numeric(correct: float, wrongs: list[float], fmt: Callable[[float], str]) -> list[str]:
    """4 distinct formatted options; collisions fixed at float AND string level."""
    vals = dedupe(correct, wrongs)
    used = {fmt(correct)}
    out = [fmt(correct)]
    for w in vals:
        s = fmt(w)
        tries = 0
        while s in used and tries < 50:  # formatting can merge distinct floats
            w = w * 1.75 + 0.013
            s = fmt(w)
            tries += 1
        if s not in used:
            used.add(s)
            out.append(s)
        if len(out) == 4:
            break
    assert len(out) == 4, f"could not build 4 distinct options for {correct}"
    return out


# ---------------------------------------------------------------------------
# TEMPLATES
# ---------------------------------------------------------------------------

def t_terminal_voltage() -> Q:
    """V = E - Ir. [NEET 2013, 2022, 2024 family]"""
    Emf = round(RNG.uniform(1.5, 24.0), 1)
    r = round(RNG.uniform(0.2, 5.0), 2)
    R = round(RNG.uniform(1.0, 50.0), 1)
    I = Emf / (R + r)
    V = Emf - I * r
    wrongs = [Emf, Emf - I * (r + R) if Emf - I * (r + R) != V else Emf + I * r, I * R + 2 * I * r]
    strs = _distinct_numeric(V, wrongs, lambda x: f"{sig(x, 3)} V")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "EMF and Internal Resistance"},
        f"A cell of emf {sig(Emf, 3)} V and internal resistance {sig(r, 3)} \u03a9 is connected across an external resistance of {sig(R, 3)} \u03a9. The terminal potential difference across the cell is:",
        strs,
        f"Current I = E/(R + r) = {sig(Emf, 3)}/({sig(R, 3)} + {sig(r, 3)}) = {sig(I, 3)} A. Terminal voltage V = E \u2212 Ir = {sig(Emf, 3)} \u2212 {sig(I, 3)} \u00d7 {sig(r, 3)} = {sig(V, 3)} V. The IR drop across the internal resistance is why the terminal voltage is less than the emf while discharging.",
        {
            "A": "reports the emf, ignoring the internal drop Ir entirely",
            "C": "uses V = E \u2212 I(R + r), wrongly dropping the external voltage too (this would be zero)",
            "D": "adds the internal drop instead of subtracting, treating the cell as being charged",
        },
        "Easy", "application", [2013, 2022],
    )


def t_stretch_wire() -> Q:
    """Wire stretched n times: R' = n^2 R (volume constant). [NEET 2013, 2017]"""
    n = RNG.choice([2, 3, 4, 5])
    R0 = round(RNG.uniform(1.0, 20.0), 1)
    Rn = n * n * R0
    wrongs = [n * R0, R0 / n, R0 / (n * n)]
    strs = _distinct_numeric(Rn, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Resistance and Resistivity"},
        f"A wire of resistance {sig(R0, 3)} \u03a9 is uniformly stretched so that its length becomes {n} times its original length. Its new resistance is:",
        strs,
        f"Stretching keeps the volume (and hence total resistance material) constant: AL = A'L', so A' = A/{n}. With R = \u03c1L/A, the new resistance is R' = \u03c1(nL)/(A/{n}) = n\u00b2R = {n}\u00b2 \u00d7 {sig(R0, 3)} = {sig(Rn, 4)} \u03a9. Length scales up by n and area scales down by n, giving the n\u00b2 factor.",
        {
            "A": "remembers the length factor n but forgets the simultaneous area shrink",
            "C": "inverts the effect \u2014 as if stretching increased the area",
            "D": "inverts the whole relation, dividing by n\u00b2",
        },
        "Medium", "application", [2013, 2017],
    )


def t_series_parallel_ratio() -> Q:
    """n equal resistors: series/parallel ratio n^2. [NEET 2018, 2021, 2023]"""
    n = RNG.choice([3, 4, 5, 6, 8, 10, 12])
    R = round(RNG.uniform(1.0, 15.0), 1)
    Rs, Rp = n * R, R / n
    ratio = Rs / Rp  # n^2
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Combination of Resistors"},
        f"{n} identical resistors, each of resistance {sig(R, 3)} \u03a9, are first connected all in series and then all in parallel to the same source. The ratio of the equivalent series resistance to the equivalent parallel resistance is:",
        [f"{ratio:.0f} : 1", f"{n} : 1", f"{ratio / 2:.0f} : 1" if ratio / 2 != n else f"{ratio + 1:.0f} : 1", f"1 : {n}"],
        f"Series: R_s = nR = {sig(Rs, 3)} \u03a9. Parallel: R_p = R/n = {sig(Rp, 3)} \u03a9. Ratio = nR \u00f7 (R/n) = n\u00b2 = {n}\u00b2 = {ratio:.0f}. The R cancels \u2014 only the count n matters.",
        {
            "B": "cancels only one factor of n instead of both",
            "C": "applies the n\u00b2 rule to the wrong pair, halving it",
            "D": "inverts the ratio \u2014 parallel resistance is smaller, so the ratio must exceed 1",
        },
        "Easy", "recall", [2018, 2021],
    )


def t_shunt_galvanometer() -> Q:
    """Ammeter conversion: S = Ig G/(I - Ig). [NEET 2026 archetype]"""
    G = RNG.choice([50.0, 100.0, 200.0, 500.0])
    Ig = RNG.choice([0.0005, 0.001, 0.002, 0.005])
    n = RNG.choice([10, 20, 25, 50, 100])
    I = n * Ig
    S = Ig * G / (I - Ig)
    wrongs = [Ig * G / I * 2 if abs(Ig * G / I * 2 - S) > 1e-12 else G / n, G / (n - 1) if abs(G / (n - 1) - S) > 1e-12 else G * n, I * G]
    strs = _distinct_numeric(S, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Moving Charges and Magnetism", "ncert_class": 12, "topic": "Galvanometer to Ammeter Conversion"},
        f"A galvanometer of resistance {sig(G, 3)} \u03a9 gives full-scale deflection for a current of {sig(Ig * 1000, 2)} mA. To convert it into an ammeter reading up to {sig(I, 3)} A, the shunt resistance required is:",
        strs,
        f"Full-scale current through the galvanometer is I_g = {sig(Ig, 4)} A; the shunt must carry I \u2212 I_g = {sig(I - Ig, 4)} A at the same voltage. Equating drops: I_g G = (I \u2212 I_g)S \u21d2 S = I_gG/(I \u2212 I_g) = {sig(Ig, 4)} \u00d7 {sig(G, 3)}/{sig(I - Ig, 4)} = {sig(S, 4)} \u03a9.",
        {
            "A": "forgets that the galvanometer still carries I_g, dividing by the full current",
            "C": "uses the current-multiplication factor n directly instead of the voltage balance",
            "D": "multiplies instead of dividing \u2014 dimensionally gives a huge resistance, not a shunt",
        },
        "Hard", "application", [2026],
    )


def t_potentiometer_emf_ratio() -> Q:
    """E1/E2 = l1/l2. [NEET 2016, 2021, 2022]"""
    l1 = float(RNG.randint(20, 90))
    l2 = float(RNG.randint(15, 95))
    if l1 == l2:
        l2 = l2 + 10
    E2 = round(RNG.uniform(0.5, 3.0), 1)
    E1 = E2 * l1 / l2
    fr = Fraction(int(round(E1 * 100)), 100)
    wrongs = [E2 * l2 / l1, E2 * (l1 + l2) / l1, E1 + 0.5 if E1 + 0.5 != E2 * (l1 + l2) / l1 else E1 * 1.5]
    strs = _distinct_numeric(E1, wrongs, lambda x: f"{sig(x, 3)} V")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Potentiometer"},
        f"In a potentiometer experiment, a cell of emf E\u2081 gives a balance point at {sig(l1, 3)} cm. When replaced by another cell of emf {sig(E2, 3)} V, the balance point shifts to {sig(l2, 3)} cm. The emf E\u2081 of the first cell is:",
        strs,
        f"At the balance (null) point no current flows through the cell, so the potential drop per cm is common: E \u221d l. Hence E\u2081/E\u2082 = l\u2081/l\u2082 \u21d2 E\u2081 = {sig(E2, 3)} \u00d7 {sig(l1, 3)}/{sig(l2, 3)} = {sig(E1, 3)} V \u2248 {float(fr):.2f} V.",
        {
            "A": "inverts the proportionality \u2014 a longer balance length means a LARGER emf",
            "C": "adds the lengths instead of forming their ratio",
            "D": "is the second emf itself, ignoring the balance-length data",
        },
        "Medium", "application", [2016, 2021],
    )


def t_heat_power_bulbs() -> Q:
    """Bulb rated (P, V) operated at V': P' = P (V'/V)^2. [NEET 2012, 2016]"""
    P = RNG.choice([25.0, 40.0, 60.0, 75.0, 100.0])
    V = RNG.choice([100.0, 110.0, 200.0, 220.0, 230.0])
    drop = RNG.uniform(0.01, 0.25)
    V2 = V * (1 - drop)
    P2 = P * (V2 / V) ** 2
    pct = (1 - (V2 / V) ** 2) * 100
    wrongs = [P * (1 - drop), P * (1 - drop) ** 2, P * drop]
    strs = _distinct_numeric(P2, wrongs, lambda x: f"{sig(x, 3)} W")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Electric Power and Energy"},
        f"A bulb rated {sig(P, 3)} W at {sig(V, 3)} V is operated on a supply whose voltage is {(1 - V2 / V) * 100:.1f}% lower than the rated value. The power consumed by the bulb is (assume resistance constant):",
        strs,
        f"R = V\u00b2/P is fixed by construction. At reduced voltage V' = {sig(V2, 3)} V: P' = V'\u00b2/R = P(V'/V)\u00b2 = {sig(P, 3)} \u00d7 ({sig(V2, 3)}/{sig(V, 3)})\u00b2 = {sig(P2, 3)} W. Because P \u221d V\u00b2, a {pct:.0f}% drop in voltage causes roughly a {pct * 2:.0f}% drop in power.",
        {
            "A": "assumes power scales linearly with voltage instead of quadratically",
            "C": "applies the quadratic factor to the wrong base (scales the deficit twice)",
            "D": "computes the deficit itself rather than the remaining power",
        },
        "Medium", "application", [2012, 2016],
    )


def t_drift_velocity() -> Q:
    """I = nA e vd. [NEET 2020, 2023, 2024]"""
    n = RNG.choice([7.0, 8.0, 8.5, 9.0]) * 1e28
    d_mm = round(RNG.uniform(0.2, 3.0), 1)
    A = PI * (d_mm * 1e-3 / 2) ** 2
    I = round(RNG.uniform(0.5, 5.0), 1)
    vd = I / (n * A * 1.6e-19)
    wrongs = [vd * 4, vd / 4, vd * 16 if vd * 16 != vd * 4 else vd / 16]
    strs = _distinct_numeric(vd, wrongs, lambda x: f"{sig(x, 3)} \u00d7 10\u207b\u2074 m/s".replace("1 \u00d7 10\u207b\u2074", "10\u207b\u2074"))
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Drift Velocity"},
        f"A copper wire of diameter {d_mm} mm carries a steady current of {sig(I, 3)} A. If the free-electron density is {sig(n / 1e28, 2)} \u00d7 10\u00b2\u2078 m\u207b\u00b3 (e = 1.6 \u00d7 10\u207b\u2079\u2070 C), the drift speed of the electrons is:",
        strs,
        f"Cross-section A = \u03c0d\u00b2/4 = {sig(A, 3)} m\u00b2. From I = neAv_d: v_d = I/(neA) = {sig(I, 3)}/({sig(n, 2)} \u00d7 10\u00b2\u2078 \u00d7 1.6 \u00d7 10\u207b\u00b9\u2079 \u00d7 {sig(A, 3)}) = {vd * 1e4:.2f} \u00d7 10\u207b\u2074 m/s. Drift speeds are fractions of a millimetre per second \u2014 the 'signal' travels fast, the electrons do not.",
        {
            "A": "loses a factor of 4 \u2014 likely used radius \u00b2 instead of diameter in A = \u03c0r\u00b2 inconsistently",
            "C": "inverts the area factor (halving the diameter should QUARTER the drift speed for fixed I)",
            "D": "squares the area error twice",
        },
        "Hard", "application", [2020, 2023, 2024],
    )


def t_resistivity_series_rods() -> Q:
    """Two rods in series: V = I(\u03c1\u2081L\u2081/A\u2081 + \u03c1\u2082L\u2082/A\u2082). [NEET 2013 (Karnataka)]"""
    L = 1.0
    A_cm2 = 0.01
    A = A_cm2 * 1e-4
    rho1 = RNG.choice([1.7e-6, 2.0e-6, 2.5e-6])  # ohm-cm scale numbers like PYQ
    rho2 = RNG.choice([1.0e-5, 1.2e-5, 1.5e-5])
    I = 1.0
    # rho given per cm, lengths in m: R = rho(ohm-cm) * L(cm)/A(cm^2)
    R1 = rho1 * (L * 100) / A_cm2
    R2 = rho2 * (L * 100) / A_cm2
    V = I * (R1 + R2)
    wrongs = [I * R1, I * R2, I * abs(R2 - R1)]
    strs = _distinct_numeric(V, wrongs, lambda x: f"{sig(x, 3)} V")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Combination of Resistors"},
        f"Two rods of equal length {sig(L, 3)} m and cross-sectional area {A_cm2} cm\u00b2 are joined end to end. One has resistivity {sig(rho1 * 1e6, 2)} \u00d7 10\u207b\u2076 \u03a9 cm and the other {sig(rho2 * 1e6, 2)} \u00d7 10\u207b\u2076 \u03a9 cm. The voltage needed to drive a current of {sig(I, 3)} A through the combination is:",
        strs,
        f"Convert: L = 100 cm. R = \u03c1L/A: R\u2081 = {sig(rho1, 2)} \u00d7 100/{A_cm2} = {sig(R1, 3)} \u03a9; R\u2082 = {sig(rho2, 2)} \u00d7 100/{A_cm2} = {sig(R2, 3)} \u03a9. In series, R = R\u2081 + R\u2082 = {sig(R1 + R2, 3)} \u03a9, so V = IR = {sig(V, 3)} V. The higher-resistivity rod dominates the drop.",
        {
            "A": "counts only the first rod \u2014 forgot the series combination",
            "C": "counts only the higher-resistivity rod",
            "D": "subtracts the resistances instead of adding (that's not any valid circuit rule here)",
        },
        "Hard", "application", [2013],
    )


def t_kirchhoff_conservation() -> Q:
    """KCL/KVL conservation laws. [AIPMT 2006, 2010]"""
    ask_first = RNG.random() < 0.5
    if ask_first:
        qt = "Kirchhoff's junction rule (current law) is a direct consequence of which conservation principle?"
        ans = "Conservation of electric charge"
        wrongs = ["Conservation of energy", "Conservation of momentum", "Conservation of mass"]
        exp = "The junction rule says the total current entering a junction equals the total leaving it. Current is the rate of flow of charge; if charge could appear or vanish at a junction the rule would fail. Hence it expresses charge conservation. (The loop rule, by contrast, expresses conservation of energy.)"
    else:
        qt = "Kirchhoff's loop rule (voltage law) is a direct consequence of which conservation principle?"
        ans = "Conservation of energy"
        wrongs = ["Conservation of electric charge", "Conservation of momentum", "Conservation of angular momentum"]
        exp = "Going around any closed loop, the sum of emfs equals the sum of IR drops \u2014 equivalently, the net change in potential is zero. If this failed, a charge completing the loop would gain energy each cycle for free, violating energy conservation. (The junction rule expresses charge conservation.)"
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Kirchhoff's Laws"},
        qt, [ans] + wrongs,
        exp,
        {
            "B": "swaps the two rules \u2014 the junction rule is about charge, the loop rule about energy",
            "C": "momentum conservation governs collisions, not circuit constraints",
            "D": "mass conservation has no role in circuit analysis",
        },
        "Easy", "recall", [2006, 2010],
    )


def t_wheatstone_balance() -> Q:
    """P/Q = R/S solve for S. [NEET 2003, 2007, 2023]"""
    P = round(RNG.uniform(1.0, 12.0), 1)
    Q = round(RNG.uniform(1.0, 20.0), 1)
    R = round(RNG.uniform(1.0, 15.0), 1)
    S = R * Q / P
    wrongs = [R * P / Q, R + Q - P, R * Q * P if R * Q * P != R * P / Q else R - Q + P]
    strs = _distinct_numeric(S, wrongs, lambda x: f"{sig(x, 3)} \u03a9")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Wheatstone Bridge"},
        f"In a Wheatstone bridge, the arms P, Q, R have resistances {sig(P, 3)} \u03a9, {sig(Q, 3)} \u03a9 and {sig(R, 3)} \u03a9 respectively. What value of the fourth-arm resistance S balances the bridge (no current through the galvanometer)?",
        strs,
        f"Balance condition: P/Q = R/S \u21d2 S = QR/P = {sig(Q, 3)} \u00d7 {sig(R, 3)}/{sig(P, 3)} = {sig(S, 3)} \u03a9. At balance the galvanometer carries no current, so the two dividers act independently and the products of opposite arms are equal (P\u00b7S = Q\u00b7R).",
        {
            "A": "multiplies the wrong pair \u2014 balance equates P\u00b7S = Q\u00b7R, not P\u00b7R = Q\u00b7S",
            "C": "adds and subtracts resistances, which has no basis for a bridge",
            "D": "multiplies all three, a dimensionally meaningless combination",
        },
        "Easy", "application", [2003, 2007],
    )


def t_temperature_coefficient() -> Q:
    """alpha = (R2 - R1)/(R1 T2 - R2 T1) or simple R = R0(1+alpha dT). [NEET 2023]"""
    R1 = round(RNG.uniform(1.0, 10.0), 2)
    T1 = float(RNG.randint(0, 40))
    T2 = float(RNG.randint(50, 150))
    alpha = round(RNG.uniform(0.002, 0.006), 5)
    R2 = R1 * (1 + alpha * (T2 - T1))
    wrongs = [R1 * (1 + alpha * T2), R1 * (1 + alpha) ** (T2 - T1), R1 + alpha * (T2 - T1)]
    strs = _distinct_numeric(R2, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Resistance and Resistivity"},
        f"The resistance of a platinum wire is {sig(R1, 3)} \u03a9 at {sig(T1, 3)} \u00b0C. Taking the temperature coefficient of resistance as {alpha} \u00b0C\u207b\u00b9, its resistance at {sig(T2, 3)} \u00b0C is:",
        strs,
        f"R = R\u2080(1 + \u03b1\u0394T) with \u0394T = {sig(T2, 3)} \u2212 {sig(T1, 3)} = {sig(T2 - T1, 3)} \u00b0C: R = {sig(R1, 3)}(1 + {alpha} \u00d7 {sig(T2 - T1, 3)}) = {sig(R2, 4)} \u03a9. Metals have positive \u03b1 \u2014 resistance rises with temperature.",
        {
            "A": "uses the absolute temperature instead of the temperature difference",
            "C": "applies the coefficient exponentially, which is wrong for the linear metal model",
            "D": "adds the fractional change as if \u03b1 were an ohm value",
        },
        "Medium", "application", [2023],
    )


def t_power_loss_transmission() -> Q:
    """P_loss = I^2 R with I = P/V. [AIPMT 2014]"""
    P = RNG.choice([10.0, 20.0, 50.0]) * 1e3  # W  (unused in variant below)
    V = RNG.choice([200.0, 400.0])
    drop_per_km = 8.0
    R_per_km = 0.5
    d_km = 150.0
    I = drop_per_km / R_per_km  # 16 A, mirrors the 2014 PYQ structure
    loss = I * I * R_per_km * 2 * d_km  # go and return wires
    loss_single = I * I * R_per_km * d_km
    wrongs = [loss_single, I * R_per_km * 2 * d_km, loss / 2 * 3 if loss / 2 * 3 != loss_single else loss * 4]
    strs = _distinct_numeric(loss, wrongs, lambda x: f"{sig(x, 4)} W")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Electric Power and Energy"},
        f"Electric power is sent {sig(d_km, 3)} km between two cities through copper wires. The fall of potential per km is {sig(drop_per_km, 3)} V and the average resistance per km is {sig(R_per_km, 3)} \u03a9. The power loss in the wires is:",
        strs,
        f"Potential fall per km: V_drop = I\u00b7R_per_km \u21d2 I = {sig(drop_per_km, 3)}/{sig(R_per_km, 3)} = {sig(I, 3)} A. The loop has go and return wires, total {sig(2 * d_km, 3)} km \u21d2 R_total = {sig(2 * d_km * R_per_km, 3)} \u03a9. Loss = I\u00b2R = {sig(I, 3)}\u00b2 \u00d7 {sig(2 * d_km * R_per_km, 3)} = {sig(loss, 4)} W. Note the loss depends on I\u00b2R \u2014 the reason power is transmitted at high voltage (low current).",
        {
            "A": "counts only one wire \u2014 the circuit needs a return path",
            "C": "forgets to square the current (that would be 'V\u00b7I' with V = the drop per km misused)",
            "D": "inflates the length factor incorrectly",
        },
        "Hard", "application", [2014],
    )


def t_cells_short_circuit() -> Q:
    """n identical cells shorted: I = nE/(nr) = E/r, independent of n. [NEET 2018]"""
    E = RNG.choice([1.5, 2.0, 2.5])
    r = RNG.choice([0.5, 1.0, 2.0])
    I = E / r
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Cells in Combination"},
        f"A battery consists of n identical cells in series, each of emf {sig(E, 3)} V and internal resistance {sig(r, 3)} \u03a9. The terminals of the battery are short-circuited. The current I as a function of n is:",
        [f"I = {sig(E, 3)}/{sig(r, 3)} A, independent of n", "I increases in proportion to n", f"I = {sig(E, 3)}/(n\u00b7{sig(r, 3)}) A", "I decreases as 1/n\u00b2"],
        f"Short-circuited: I = nE/(nr) \u2014 the n cancels exactly. Both available emf and total internal resistance grow as n, so I = {sig(E, 3)}/{sig(r, 3)} = {sig(I, 3)} A for every n. A classic 'looks like it should scale' trap.",
        {
            "B": "sees more cells, more emf \u2014 but forgets the internal resistances add too",
            "C": "divides by n as if only resistance grew",
            "D": "no quadratic factor appears anywhere in a series-cell loop",
        },
        "Medium", "analysis", [2018],
    )


def t_potentiometer_internal_resistance() -> Q:
    """r = R(l1 - l2)/l2. [AIPMT 2008, 2014]"""
    R = round(RNG.uniform(2.0, 15.0), 1)
    l1 = float(RNG.randint(60, 130))
    l2 = float(RNG.randint(30, 110))
    if l2 >= l1:
        l1, l2 = l2 + 20, l1
    r = R * (l1 - l2) / l2
    wrongs = [R * l2 / (l1 - l2) if R * l2 / (l1 - l2) != r else R * 2, R * (l1 - l2) / l1, R * (l1 + l2) / l2]
    strs = _distinct_numeric(r, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Potentiometer"},
        f"In a potentiometer experiment for measuring internal resistance, a cell balanced at {sig(l1, 3)} cm when open-circuited gives a balance at {sig(l2, 3)} cm when shunted by R = {sig(R, 3)} \u03a9. The internal resistance of the cell is:",
        strs,
        f"Open circuit: emf \u221d l\u2081. With shunt R the terminal voltage \u221d l\u2082, and V = ER/(R + r). So l\u2082/l\u2081 = R/(R + r) \u21d2 r = R(l\u2081 \u2212 l\u2082)/l\u2082 = {sig(R, 3)} \u00d7 ({sig(l1, 3)} \u2212 {sig(l2, 3)})/{sig(l2, 3)} = {sig(r, 4)} \u03a9.",
        {
            "A": "inverts the fraction \u2014 (l\u2081 \u2212 l\u2082) belongs in the numerator over l\u2082",
            "C": "normalises by the wrong length l\u2081",
            "D": "adds the lengths, which has no physical meaning here",
        },
        "Hard", "application", [2008, 2014],
    )


def t_wire_cut_rejoin() -> Q:
    """Cut into n equal parts, m in parallel, rest in series etc. [NEET 2024, 2025]"""
    n = RNG.choice([4, 5, 8, 10])
    R0 = RNG.choice([4.0, 5.0, 10.0, 12.0, 50.0])
    piece = R0 / n
    mode = RNG.choice(["series_parallel", "all_parallel"])
    if mode == "all_parallel":
        Req = piece / n
        qt = (f"A wire of resistance {sig(R0, 3)} \u03a9 is cut into {n} equal pieces, and all {n} pieces are connected in parallel. "
              f"The equivalent resistance is:")
        exp = (f"Each piece has resistance R/{n} = {sig(piece, 3)} \u03a9. {n} equal resistors in parallel: R_eq = ({sig(piece, 3)})/{n} "
               f"= R/n\u00b2 = {sig(Req, 4)} \u03a9.")
        wrongs = [piece, R0 / n / 2 if R0 / n / 2 != piece else R0 / (n * 4), R0]
        ans_strs = _distinct_numeric(Req, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
        diff, pyq = "Medium", [2024]
    else:
        # first 5 in series, next 5 in parallel, in series (NEET 2024 style, n=10)
        Req = piece * 5 + piece / 5
        qt = (f"A wire of resistance {sig(R0, 3)} \u03a9 is divided into 10 equal parts. The first 5 parts are connected in series, "
              f"the next 5 parts in parallel, and the two combinations are then joined in series. The total resistance is:")
        exp = (f"Each part: R/10 = {sig(piece, 3)} \u03a9. Five in series: 5R/10 = {sig(5 * piece, 3)} \u03a9. Five in parallel: R/50 = "
               f"{sig(piece / 5, 3)} \u03a9. Total = {sig(5 * piece, 3)} + {sig(piece / 5, 3)} = {sig(Req, 4)} \u03a9.")
        wrongs = [5 * piece, piece / 5, R0]
        ans_strs = _distinct_numeric(Req, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
        diff, pyq = "Hard", [2024]
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Combination of Resistors"},
        qt, ans_strs, exp,
        {
            "A": "forgot that cutting also divides each piece's resistance by n before recombining",
            "C": "handled only the parallel half correctly, ignoring the series half",
            "D": "reports the original uncut resistance",
        },
        diff, "application", pyq,
    )


def t_capacitor_energy() -> Q:
    """U = 1/2 CV^2. [NEET 2024]"""
    C = RNG.choice([1.0, 2.0, 3.0, 6.0, 12.0])
    V = round(RNG.uniform(5.0, 100.0), 0)
    U = 0.5 * C * 1e-12 * V * V
    wrongs = [C * 1e-12 * V * V, 0.25 * C * 1e-12 * V * V, 0.5 * C * 1e-12 * V]
    strs = _distinct_numeric(U, wrongs, lambda x: f"{sig(x * 1e9, 3)} nJ")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Electrostatic Potential and Capacitance", "ncert_class": 12, "topic": "Energy Stored in a Capacitor"},
        f"A {sig(C, 3)} pF capacitor is connected to a {sig(V, 3)} V battery. The energy stored in the capacitor is:",
        strs,
        f"U = \u00bdCV\u00b2 = \u00bd \u00d7 {sig(C, 3)} \u00d7 10\u207b\u00b9\u00b2 F \u00d7 ({sig(V, 3)})\u00b2 = {sig(U * 1e9, 3)} nJ. Note the factor \u00bd: the battery does CV\u00b2 of work, half of which is stored and half dissipated while charging.",
        {
            "A": "drops the factor \u00bd \u2014 that's the battery's work, not the stored energy",
            "C": "uses \u00bc instead of \u00bd",
            "D": "is linear in V \u2014 energy goes as the SQUARE of the voltage",
        },
        "Medium", "application", [2024],
    )


def t_coulomb_force() -> Q:
    """F = kq1q2/r^2. [classic NEET/AIPMT]"""
    q1 = round(RNG.uniform(0.5, 10.0), 1)
    q2 = round(RNG.uniform(0.5, 10.0), 1)
    r_cm = round(RNG.uniform(2.0, 50.0), 1)
    r = r_cm / 100
    k = 9e9
    F = k * q1 * 1e-9 * q2 * 1e-9 / (r * r)  # nC charges
    wrongs = [F * 2, F / 2, F * 4 if F * 4 != F * 2 else F / 4]
    strs = _distinct_numeric(F, wrongs, lambda x: f"{sig(x, 3)} \u00d7 10\u207b\u2075 N" if F < 1e-3 else f"{sig(x * 1e3, 3)} mN")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Electric Charges and Fields", "ncert_class": 12, "topic": "Coulomb's Law"},
        f"Two point charges {sig(q1, 3)} nC and {sig(q2, 3)} nC are {sig(r_cm, 3)} cm apart in vacuum. The electrostatic force between them is (1/4\u03c0\u03b5\u2080 = 9 \u00d7 10\u2079 N m\u00b2 C\u207b\u00b2):",
        strs,
        f"F = kq\u2081q\u2082/r\u00b2 = 9\u00d710\u2079 \u00d7 {sig(q1, 3)}e\u22129 \u00d7 {sig(q2, 3)}e\u22129 / ({sig(r, 3)})\u00b2 \u2248 {F:.3e} N. Both charges are nanocoulombs (10\u207b\u2079 C) and the distance must be in metres \u2014 two unit conversions are the whole game here.",
        {
            "A": "doubles instead of computing the product",
            "C": "forgets to convert cm to m (a 10\u2074 error) or nC to C (another 10\u2079) \u2014 net error here simplifies to half",
            "D": "misses the square on r",
        },
        "Medium", "application", [2015],
    )


def t_ohm_resistivity_wire() -> Q:
    """R = rho L/A with geometry change. [AIPMT 2004, NEET 2017]"""
    mode = RNG.random()
    if mode < 0.5:
        factor = RNG.choice([2, 3, 4])
        R0 = RNG.choice([2.0, 4.0, 8.0])
        # length and diameter both scaled by 'factor'
        Rn = R0 / factor  # R ~ L/d^2 -> factor L / factor^2 d^2 = R0/factor
        qt = (f"A wire of resistance {sig(R0, 3)} \u03a9 has its length and its diameter both increased {factor} times. "
              f"The new resistance is:")
        exp = (f"R = \u03c1L/A = \u03c1L/(\u03c0d\u00b2/4) \u221d L/d\u00b2. New: L' = {factor}L, d' = {factor}d \u21d2 "
               f"R' = R\u2080 \u00b7 {factor}/{factor}\u00b2 = R\u2080/{factor} = {sig(Rn, 3)} \u03a9.")
        wrongs = [R0 * factor, R0 * factor * factor, R0 / factor / factor]
        strs = _distinct_numeric(Rn, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
        diff = "Medium"
    else:
        R0 = RNG.choice([4.0, 8.0, 12.0])
        n = 2
        Rn = n * n * R0
        qt = f"A wire of resistance {sig(R0, 3)} \u03a9 is melted and stretched to twice its original length. Its new resistance is:"
        exp = (f"Volume is conserved on stretching: A' = A/2. R' = \u03c1(2L)/(A/2) = 4\u03c1L/A = 4R\u2080 = {sig(Rn, 3)} \u03a9.")
        wrongs = [n * R0, R0, R0 / (n * n)]
        strs = _distinct_numeric(Rn, wrongs, lambda x: f"{sig(x, 4)} \u03a9")
        diff = "Medium"
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Resistance and Resistivity"},
        qt, strs, exp,
        {
            "A": "applies the length scaling but forgets the area term",
            "C": "scales both effects in the same direction",
            "D": "inverts the scaling",
        },
        diff, "application", [2004, 2017],
    )


def t_projectile_range() -> Q:
    """R = u^2 sin 2theta / g. [NEET recurring kinematics]"""
    u = round(RNG.uniform(5.0, 40.0), 1)
    theta = RNG.choice([15.0, 20.0, 25.0, 30.0, 45.0, 60.0, 75.0])
    g = 10.0
    R = u * u * math.sin(2 * math.radians(theta)) / g
    s2 = math.sin(2 * math.radians(theta))
    wrongs = [u * u / (2 * g), u * u * math.sin(math.radians(theta)) / g, u * u / g]
    strs = _distinct_numeric(R, wrongs, lambda x: f"{sig(x, 4)} m")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Motion in a Plane", "ncert_class": 11, "topic": "Projectile Motion"},
        f"A projectile is launched with speed {sig(u, 3)} m/s at {sig(theta, 3)}\u00b0 above the horizontal. Taking g = 10 m/s\u00b2, its horizontal range is:",
        strs,
        f"R = u\u00b2sin2\u03b8/g = {sig(u, 3)}\u00b2 \u00d7 sin{sig(2 * theta, 3)}\u00b0/10 = {sig(u * u, 3)} \u00d7 {sig(s2, 3)}/10 = {sig(R, 4)} m. Range is maximal at 45\u00b0 (sin 90\u00b0 = 1), and \u03b8 and 90\u00b0 \u2212 \u03b8 give equal ranges.",
        {
            "A": "is the maximum height u\u00b2sin\u00b2\u03b8/2g, not the range",
            "C": "used sin\u03b8 instead of sin2\u03b8",
            "D": "forgot the trigonometric factor completely (45\u00b0-only shortcut misapplied)",
        },
        "Medium", "application", [2019],
    )


def t_shm_time_period() -> Q:
    """T = 2\u03c0\u221a(m/k) spring-mass. [NEET recurring oscillations]"""
    m = round(RNG.uniform(0.05, 5.0), 2)
    k = round(RNG.uniform(20.0, 1000.0), 1)
    T = 2 * PI * math.sqrt(m / k)
    wrongs = [2 * PI * m / k, PI * math.sqrt(m / k), 2 * PI * math.sqrt(k / m)]
    strs = _distinct_numeric(T, wrongs, lambda x: f"{sig(x, 3)} s")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Oscillations", "ncert_class": 11, "topic": "Simple Harmonic Motion"},
        f"A block of mass {sig(m, 3)} kg on a frictionless surface is attached to a spring of force constant {sig(k, 3)} N/m and set into horizontal SHM. The time period of oscillation is:",
        strs,
        f"T = 2\u03c0\u221a(m/k) = 2\u03c0\u221a({sig(m, 3)}/{sig(k, 3)}) = 2\u03c0\u221a({sig(m / k, 4)}) \u2248 {T:.3f} s. Doubling m multiplies T by \u221a2; quadrupling k halves T.",
        {
            "A": "linearised the square root \u2014 T depends on \u221a(m/k), not m/k",
            "C": "dropped the factor 2\u03c0 (that's the angular frequency \u03c9)",
            "D": "inverted the mass-spring ratio \u2014 a stiffer spring shortens T",
        },
        "Medium", "application", [2021],
    )


def t_lens_power() -> Q:
    """P = 1/f(m) in dioptres; combination P = P1 + P2. [NEET recurring ray optics]"""
    f1_cm = RNG.choice([5, 10, 12.5, 15, 20, 25, 30, 40, 50, 60])
    f2_cm = RNG.choice([5, 10, 12.5, 15, 20, 25, 30, 40, 50, 60])
    P = 100 / f1_cm + 100 / f2_cm
    wrongs = [100 / (f1_cm + f2_cm), abs(100 / f1_cm - 100 / f2_cm), 100 / f1_cm + 100 / f2_cm / 2]
    strs = _distinct_numeric(P, wrongs, lambda x: f"{sig(x, 3)} D")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Ray Optics and Optical Instruments", "ncert_class": 12, "topic": "Thin Lens Formula"},
        f"Two thin convex lenses of focal lengths {sig(f1_cm, 3)} cm and {sig(f2_cm, 3)} cm are placed in contact. The power of the combination is:",
        strs,
        f"Convert to metres: f\u2081 = {sig(f1_cm / 100, 3)} m \u2192 P\u2081 = 1/f\u2081 = +{sig(100 / f1_cm, 3)} D; f\u2082 = {sig(f2_cm / 100, 3)} m \u2192 P\u2082 = +{sig(100 / f2_cm, 3)} D. For thin lenses in contact P = P\u2081 + P\u2082 = {sig(P, 3)} D.",
        {
            "A": "added focal lengths then inverted \u2014 powers add, not reciprocal of the sum",
            "C": "subtracted \u2014 that would apply if one lens were concave",
            "D": "halved one contribution incorrectly",
        },
        "Easy", "application", [2018],
    )


def t_wave_optics_ydse() -> Q:
    """Fringe width beta = lambda D/d. [NEET recurring wave optics]"""
    lam_nm = RNG.randint(380, 750)
    lam = lam_nm * 1e-9
    D_mm = RNG.randint(250, 2500)
    D = D_mm * 1e-3
    d_mm = round(RNG.uniform(0.1, 1.5), 2)
    d = d_mm * 1e-3
    beta = lam * D / d
    wrongs = [beta * 2, beta / 2, lam * d / D]
    strs = _distinct_numeric(beta, wrongs, lambda x: f"{sig(x, 3)} mm" if beta < 1e-3 else f"{sig(x * 1000, 3)} mm")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Wave Optics", "ncert_class": 12, "topic": "Young's Double Slit Experiment"},
        f"In a Young's double-slit experiment, light of wavelength {lam_nm} nm is used with slits {sig(d_mm, 3)} mm apart, the screen being {sig(D_mm, 3)} mm away. The fringe width is:",
        strs,
        f"\u03b2 = \u03bbD/d = ({lam_nm} \u00d7 10\u207b\u2079)({D_mm} \u00d7 10\u207b\u00b3)/({d_mm} \u00d7 10\u207b\u00b3) = {beta * 1000:.3f} mm. Fringe width grows with wavelength and screen distance, shrinks with slit separation \u2014 all three unit conversions (nm, mm) must be done consistently.",
        {
            "A": "doubles \u03b2 \u2014 fringe width is the spacing between successive bright (or dark) bands, not the bright-dark pair spacing",
            "C": "halved the expression arbitrarily",
            "D": "inverted the D/d ratio \u2014 moving the screen farther must WIDEN fringes",
        },
        "Medium", "application", [2022],
    )


def t_photoelectric_kmax() -> Q:
    """Kmax = hv - phi; stopping potential. [NEET recurring modern physics]"""
    phi_eV = round(RNG.uniform(1.0, 3.5), 2)
    E_eV = round(phi_eV + RNG.uniform(0.2, 3.0), 2)
    K = E_eV - phi_eV
    wrongs = [E_eV + phi_eV, E_eV, phi_eV]
    strs = _distinct_numeric(K, wrongs, lambda x: f"{sig(x, 3)} eV")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Dual Nature of Radiation and Matter", "ncert_class": 12, "topic": "Photoelectric Effect"},
        f"Light of energy {sig(E_eV, 3)} eV falls on a metal of work function {sig(phi_eV, 3)} eV. The maximum kinetic energy of the emitted photoelectrons is:",
        strs,
        f"Einstein's photoelectric equation: K_max = h\u03bd \u2212 \u03c6 = {sig(E_eV, 3)} \u2212 {sig(phi_eV, 3)} = {sig(K, 3)} eV. The work function is the escape tax paid by every electron; only the excess appears as kinetic energy (of the fastest electrons).",
        {
            "A": "added the energies \u2014 the photon energy is the SOURCE, not an addition to the work function",
            "C": "reports the photon energy, ignoring the work function",
            "D": "reports the work function, ignoring the photon energy",
        },
        "Easy", "application", [2019, 2023],
    )


def t_bohr_radius_energy() -> Q:
    """E_n = -13.6/n^2 eV. [NEET recurring atoms]"""
    n = RNG.choice([2, 3, 4, 5, 6])
    E = -13.6 / (n * n)
    wrongs = [-13.6 / n, -13.6 / (n ** 3), -13.6 * n]
    strs = _distinct_numeric(E, wrongs, lambda x: f"{sig(x, 3)} eV")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Atoms", "ncert_class": 12, "topic": "Bohr Model"},
        f"According to the Bohr model, the energy of an electron in the n = {n} orbit of a hydrogen atom is:",
        strs,
        f"E\u2099 = \u221213.6/n\u00b2 eV = \u221213.6/{n}\u00b2 = {sig(E, 3)} eV. Energies are negative (bound states) and approach zero as n \u2192 \u221e \u2014 the n\u00b2 makes higher levels crowd together near zero.",
        {
            "A": "divides by n instead of n\u00b2 \u2014 that's the momentum-quantisation level spacing pattern, not energy",
            "C": "cubes the denominator",
            "D": "energy must be negative for a bound orbit; multiplying by n makes no physical sense",
        },
        "Easy", "recall", [2018, 2022],
    )


def t_magnetic_field_loop() -> Q:
    """B at centre of circular loop = mu0 I / 2R. [NEET recurring]"""
    I = round(RNG.uniform(0.5, 20.0), 1)
    R_cm = round(RNG.uniform(2.0, 50.0), 1)
    R = R_cm / 100
    B = (4 * PI * 1e-7 * I) / (2 * R)
    turns = RNG.choice([1, 1, 5, 10, 25, 50, 100])
    Bt = B * turns
    wrongs = [Bt * 2, Bt / 2, (4 * PI * 1e-7 * I) / R * turns]
    strs = _distinct_numeric(Bt, wrongs, lambda x: f"{sig(x, 3)} \u00d7 10\u207b\u2075 T" if Bt < 1e-4 else f"{sig(x * 1e5, 3)} \u00d7 10\u207b\u2075 T")
    label = "turns" if turns > 1 else "turn"
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Moving Charges and Magnetism", "ncert_class": 12, "topic": "Magnetic Field due to a Current"},
        f"A circular coil of radius {sig(R_cm, 3)} cm and {turns} {label} carries a current of {sig(I, 3)} A. The magnetic field at its centre is (\u03bc\u2080 = 4\u03c0 \u00d7 10\u207b\u2077 T m/A):",
        strs,
        f"B = \u03bc\u2080NI/2R = (4\u03c0 \u00d7 10\u207b\u2077 \u00d7 {turns} \u00d7 {sig(I, 3)})/(2 \u00d7 {sig(R, 3)}) = {Bt:.3e} T. The 2 in the denominator matters \u2014 the field at the centre of a LOOP is half what you'd get by naively using \u03bc\u2080I/2\u03c0R.",
        {
            "A": "doubled the field (used \u03bc\u2080I/R)",
            "C": "halved it again",
            "D": "used the long-straight-wire denominator 2\u03c0R instead of 2R",
        },
        "Medium", "application", [2020],
    )


def t_momentum_photon() -> Q:
    """p = E/c = h/lambda. [NEET recurring]"""
    E_eV = round(RNG.uniform(0.5, 6.5), 2)
    J = E_eV * 1.6e-19
    p = J / 3e8
    wrongs = [p * 3e8, J * 3e8, p / 2]
    strs = _distinct_numeric(p, wrongs, lambda x: f"{sig(x, 3)} kg m/s")
    lam_nm = 1240 / E_eV
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Dual Nature of Radiation and Matter", "ncert_class": 12, "topic": "Photon Nature of Light"},
        f"A photon has energy {sig(E_eV, 3)} eV. Its momentum is (1 eV = 1.6 \u00d7 10\u207b\u00b9\u2079 J, c = 3 \u00d7 10\u2078 m/s):",
        strs,
        f"Convert: E = {sig(E_eV, 3)} \u00d7 1.6\u00d710\u207b\u00b9\u2079 = {J:.3e} J. Photon momentum p = E/c = {J:.3e}/(3\u00d710\u2078) = {p:.3e} kg m/s. Equivalently p = h/\u03bb with \u03bb = 1240/{sig(E_eV, 3)} \u2248 {sig(lam_nm, 3)} nm.",
        {
            "A": "multiplied by c instead of dividing",
            "C": "a unit error inflating by c\u00b2 \u2014 E = mc\u00b2 is for MASS, not photons",
            "D": "halved without reason",
        },
        "Medium", "application", [2021],
    )


def t_gravitation_Weight() -> Q:
    """g at height h: g' = g R^2/(R+h)^2. [NEET recurring gravitation]"""
    h_factor = RNG.choice([1, 2])
    R = 6400.0
    g = 9.8
    h = h_factor * R
    gp = g * R * R / (R + h) ** 2
    wrongs = [g / (1 + h_factor), g / (1 + h_factor) ** 3, g * (1 - h_factor * 0.25)]
    strs = _distinct_numeric(gp, wrongs, lambda x: f"{sig(x, 3)} m/s\u00b2")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Gravitation", "ncert_class": 11, "topic": "Variation of g with Height"},
        f"The acceleration due to gravity at the Earth's surface is 9.8 m/s\u00b2. At a height h = {h_factor}R above the surface (R = Earth's radius), the value of g is:",
        strs,
        f"g' = gR\u00b2/(R + h)\u00b2 = gR\u00b2/((1 + {h_factor})R)\u00b2 = g/(1 + {h_factor})\u00b2 = 9.8/{(1 + h_factor) ** 2} = {gp:.2f} m/s\u00b2. The inverse-SQUARE law is the key \u2014 distance from the CENTRE, not from the surface.",
        {
            "A": "used an inverse-first-power law",
            "C": "cubed the distance factor \u2014 that has no basis for g",
            "D": "a linear interpolation guess",
        },
        "Medium", "application", [2020],
    )


def t_bernoulli_or_viscosity() -> Q:
    """Terminal velocity v \u221d r^2 (Stokes). [NEET recurring properties of matter]"""
    v1 = round(RNG.uniform(0.5, 10.0), 2)
    f = RNG.choice([2, 3, 4])
    v2 = v1 * f * f
    wrongs = [v1 * f, v1 * f ** 3, v1 / f]
    strs = _distinct_numeric(v2, wrongs, lambda x: f"{sig(x, 3)} cm/s")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Mechanical Properties of Fluids", "ncert_class": 11, "topic": "Viscosity and Terminal Velocity"},
        f"A small sphere falls through a viscous liquid with terminal velocity {sig(v1, 3)} cm/s. If a sphere of the same material but {f} times the radius is used, its terminal velocity will be (Stokes' law regime):",
        strs,
        f"Terminal velocity v = 2r\u00b2(\u03c1 \u2212 \u03c3)g/9\u03b7 \u221d r\u00b2 for the same material and fluid. Radius {f}\u00d7 \u21d2 v' = {f}\u00b2 \u00d7 {sig(v1, 3)} = {sig(v2, 3)} cm/s. Mass grows as r\u00b3 but drag as r\u00b7v \u2014 net effect v \u221d r\u00b2.",
        {
            "A": "scales linearly with radius \u2014 forgot the r\u00b2 in Stokes' law",
            "C": "used r\u00b3 (mass scaling) instead of r\u00b2",
            "D": "reduced the speed \u2014 bigger spheres fall FASTER",
        },
        "Medium", "application", [2021],
    )


def t_thermo_efficiency() -> Q:
    """Carnot eta = 1 - Tc/Th. [NEET recurring thermodynamics]"""
    Th = float(RNG.randint(400, 1000))
    Tc = float(RNG.randint(250, 380))
    if Tc >= Th:
        Tc = Th - 100
    eff = 1 - Tc / Th
    pct = eff * 100
    wrongs = [Tc / Th * 100, (1 - Tc / Th) * 50, eff * 200 if eff * 200 != pct else eff * 100 / 3]
    strs = _distinct_numeric(pct, wrongs, lambda x: f"{sig(x, 3)}%")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Thermodynamics", "ncert_class": 11, "topic": "Heat Engines and Carnot Cycle"},
        f"A Carnot engine operates between a source at {sig(Th, 3)} K and a sink at {sig(Tc, 3)} K. Its efficiency is:",
        strs,
        f"\u03b7 = 1 \u2212 T_c/T_h = 1 \u2212 {sig(Tc, 3)}/{sig(Th, 3)} = {eff:.3f} \u2248 {pct:.0f}%. Temperatures MUST be absolute (kelvin) \u2014 a Celsius plug-in is the classic error here.",
        {
            "A": "reports the fraction of energy WASTED (Tc/Th), not the efficiency",
            "C": "an arbitrary halving of the correct fraction",
            "D": "exceeds the Carnot bound in many parameterisations \u2014 no engine can beat 1 \u2212 Tc/Th",
        },
        "Medium", "application", [2022],
    )


def t_work_energy_spring() -> Q:
    """Spring PE = 1/2 kx^2. [NEET recurring WEP]"""
    k = RNG.choice([100.0, 200.0, 400.0, 500.0, 800.0, 1000.0])
    x_cm = round(RNG.uniform(1.0, 25.0), 1)
    x = x_cm / 100
    U = 0.5 * k * x * x
    wrongs = [k * x * x, 0.25 * k * x * x, 0.5 * k * x]
    strs = _distinct_numeric(U, wrongs, lambda x_: f"{sig(x_, 3)} J")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Work, Energy and Power", "ncert_class": 11, "topic": "Potential Energy of a Spring"},
        f"A spring of force constant {sig(k, 3)} N/m is compressed by {sig(x_cm, 3)} cm. The elastic potential energy stored in it is:",
        strs,
        f"U = \u00bdkx\u00b2 = \u00bd \u00d7 {sig(k, 3)} \u00d7 ({sig(x, 3)})\u00b2 = {U:.3f} J. Extension must be in metres; energy grows with the SQUARE of the compression.",
        {
            "A": "dropped the \u00bd \u2014 that's the total area under F-x only if F were constant, which it is not for a spring",
            "C": "used \u00bc instead of \u00bd",
            "D": "linear in x \u2014 misses the square",
        },
        "Easy", "application", [2019],
    )


def t_nuclei_half_life() -> Q:
    """N = N0 (1/2)^(t/T). [NEET recurring nuclei]"""
    T = round(RNG.uniform(0.5, 30.0), 1)
    n_half = RNG.randint(1, 4)
    t = n_half * T
    N0 = 100.0
    N = N0 / 2 ** n_half
    wrongs = [N0 / n_half if n_half > 1 else 25.0, N0 / 2 ** (n_half + 1), N0 * (0.9 ** t)]
    wrongs = [w for w in wrongs if w != N]
    if len(wrongs) < 3:
        wrongs.append(N + 7.5)
    strs = _distinct_numeric(N, wrongs[:3], lambda x_: f"{sig(x_, 3)}%")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Nuclei", "ncert_class": 12, "topic": "Radioactive Decay Law"},
        f"A radioactive sample has a half-life of {sig(T, 3)} days. Starting with 100% activity, the fraction remaining after {sig(t, 3)} days is:",
        strs,
        f"Number of half-lives = t/T = {sig(t, 3)}/{sig(T, 3)} = {n_half}. Remaining = (1/2)^{n_half} = {N:.2f}%. Decay is exponential in TIME, not linear.",
        {
            "A": "divided linearly by the half-life count",
            "C": "off by one half-life in the exponent",
            "D": "invented a linear decay model",
        },
        "Easy", "application", [2019, 2023],
    )


def t_emf_induced() -> Q:
    """Faraday: emf = -N dPhi/dt = NBA(omega) for rotating coil peak. [NEET recurring EMI]"""
    B = round(RNG.uniform(0.05, 1.0), 2)
    N = RNG.choice([50, 100, 200, 500, 1000])
    A_cm2 = round(RNG.uniform(50.0, 500.0), 0)
    A = A_cm2 * 1e-4
    f = RNG.choice([50.0, 100.0])
    omega = 2 * PI * f
    e0 = N * B * A * omega
    wrongs = [e0 / (2 * PI), e0 / 2, N * B * A]
    strs = _distinct_numeric(e0, wrongs, lambda x: f"{sig(x, 3)} V")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Electromagnetic Induction", "ncert_class": 12, "topic": "Faraday's Law"},
        f"A coil with {N} turns of area {sig(A_cm2, 3)} cm\u00b2 rotates at {sig(f, 3)} Hz in a magnetic field of {sig(B, 3)} T (axis \u22a5 to B). The peak emf generated is:",
        strs,
        f"Flux \u03a6 = NBA cos\u03c9t \u21d2 peak emf e\u2080 = NBA\u03c9 = {N} \u00d7 {sig(B, 3)} \u00d7 {sig(A, 4)} \u00d7 2\u03c0({sig(f, 3)}) = {e0:.1f} V. cm\u00b2 \u2192 m\u00b2 and Hz \u2192 rad/s are the two conversions that decide the answer.",
        {
            "A": "dropped the 2\u03c0 \u2014 that's flux amplitude times N, not a rate of change",
            "C": "halved the amplitude \u2014 \u221a2 factors belong to rms values, not peaks",
            "D": "reports NBA without differentiating \u2014 a static flux induces nothing",
        },
        "Hard", "application", [2022],
    )


def t_resolution_telescope() -> Q:
    """RP = D/1.22 lambda. [NEET recurring wave optics modern]"""
    D_m = RNG.choice([0.5, 1.0, 2.0, 2.5, 5.0, 10.0])
    lam_nm = RNG.randint(400, 750)
    lam = lam_nm * 1e-9
    theta = 1.22 * lam / D_m
    wrongs = [theta * 1.22, theta / 1.22, 1.22 * lam * D_m]
    strs = _distinct_numeric(theta, wrongs, lambda x: f"{sig(x, 3)} rad")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Wave Optics", "ncert_class": 12, "topic": "Resolving Power"},
        f"A telescope objective of diameter {sig(D_m, 3)} m receives light of wavelength {lam_nm} nm. The angular limit of resolution is (1.22 factor for circular aperture):",
        strs,
        f"\u03b8 = 1.22\u03bb/D = 1.22 \u00d7 {lam_nm} \u00d7 10\u207b\u2079/{sig(D_m, 3)} = {theta:.3e} rad. Bigger aperture \u2192 smaller \u03b8 \u2192 finer detail; the 1.22 comes from the circular aperture's Airy pattern.",
        {
            "A": "multiplied the 1.22 twice",
            "C": "cancelled the 1.22 \u2014 that factor is needed for circular, not slit, apertures",
            "D": "multiplied by D instead of dividing",
        },
        "Medium", "application", [2023],
    )


def t_ohmic_heating_kettle() -> Q:
    """H = I^2 R t with unit conversions. [AIPMT 2008 style]"""
    I = round(RNG.uniform(0.5, 10.0), 1)
    R = round(RNG.uniform(5.0, 100.0), 1)
    t_min = RNG.randint(1, 10)
    H = I * I * R * t_min * 60
    wrongs = [I * R * t_min * 60, I * I * R * t_min, H / 60]
    strs = _distinct_numeric(H, wrongs, lambda x: f"{sig(x, 4)} J")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Current Electricity", "ncert_class": 12, "topic": "Heating Effect of Current"},
        f"A current of {sig(I, 3)} A flows through a resistor of {sig(R, 3)} \u03a9 for {t_min} minute(s). The heat produced is:",
        strs,
        f"H = I\u00b2Rt = {sig(I, 3)}\u00b2 \u00d7 {sig(R, 3)} \u00d7 {t_min} \u00d7 60 s = {H:.1f} J. Time must be in SECONDS for joules \u2014 the minute-to-second conversion is where most marks are lost.",
        {
            "A": "linear in I \u2014 Joule heating goes as I\u00b2",
            "C": "forgot to convert minutes to seconds",
            "D": "an order-of-60 slip",
        },
        "Easy", "application", [2008],
    )


def t_vector_addition() -> Q:
    """Two perpendicular vectors magnitude. [NEET recurring]"""
    a = RNG.choice([3, 4, 5, 6, 8])
    b = RNG.choice([4, 3, 12, 5])
    if a == b:
        b = b + 1
    mag = math.hypot(a, b)
    wrongs = [a + b, abs(a - b), math.sqrt(a * a + b * b) / 2 if a != b else a + b]
    strs = _distinct_numeric(mag, wrongs, lambda x: f"{sig(x, 4)}")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Motion in a Plane", "ncert_class": 11, "topic": "Vectors"},
        f"Two perpendicular vectors have magnitudes {a} units and {b} units. The magnitude of their resultant is:",
        strs,
        f"For perpendicular vectors R = \u221a(a\u00b2 + b\u00b2) = \u221a({a}\u00b2 + {b}\u00b2) = \u221a{a * a + b * b} = {mag:.2f}. Simple addition ({a + b}) only applies when the vectors are COLLINEAR and same-sense.",
        {
            "A": "added magnitudes directly \u2014 valid only for parallel vectors",
            "C": "subtracted \u2014 valid for antiparallel vectors",
            "D": "half the correct resultant",
        },
        "Easy", "application", None,
    )


def t_relativity_gamma() -> Q:
    """Length contraction L = L0 sqrt(1 - v^2/c^2). [NEET modern physics]"""
    beta = RNG.choice([0.6, 0.8])
    L0 = RNG.choice([1.0, 2.0, 100.0])
    L = L0 * math.sqrt(1 - beta * beta)
    wrongs = [L0 * beta, L0 / math.sqrt(1 - beta * beta), L0 * (1 - beta * beta)]
    strs = _distinct_numeric(L, wrongs, lambda x: f"{sig(x, 4)} m" if L0 <= 2 else f"{sig(x, 4)} m")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Dual Nature of Radiation and Matter", "ncert_class": 12, "topic": "Special Relativity Basics"},
        f"A rod of proper length {sig(L0, 3)} m moves along its length at v = {beta}c. Its contracted length as measured in the lab frame is:",
        strs,
        f"L = L\u2080\u221a(1 \u2212 v\u00b2/c\u00b2) = {sig(L0, 3)}\u221a(1 \u2212 {beta}\u00b2) = {sig(L0, 3)} \u00d7 {math.sqrt(1 - beta * beta):.1f} = {L:.2f} m. The 3-4-5 triple (v = 0.6c \u2192 \u03b3 = 1.25; v = 0.8c \u2192 \u03b3 = 5/3) makes these computable by hand.",
        {
            "A": "scaled by \u03b2 itself, not \u221a(1 \u2212 \u03b2\u00b2)",
            "C": "DILATED instead of contracted (used \u03b3 = 1/\u221a(1 \u2212 \u03b2\u00b2))",
            "D": "used 1 \u2212 \u03b2\u00b2 without the square root",
        },
        "Medium", "application", None,
    )


def t_center_of_mass() -> Q:
    """Two-mass COM position. [NEET recurring rotational/COM]"""
    m1 = RNG.choice([1.0, 2.0, 3.0])
    m2 = RNG.choice([1.0, 2.0, 3.0, 6.0])
    if m1 == m2:
        m2 = m2 + 1
    d = RNG.choice([1.0, 2.0, 4.0])
    x = m2 * d / (m1 + m2)
    wrongs = [d / 2, m1 * d / (m1 + m2), d * m1 * m2 / (m1 + m2)]
    strs = _distinct_numeric(x, wrongs, lambda x_: f"{sig(x_, 3)} m")
    return _mk(
        {"id": "", "subject": "Physics", "chapter": "Center of Mass and Collision", "ncert_class": 11, "topic": "Center of Mass"},
        f"Masses {sig(m1, 3)} kg and {sig(m2, 3)} kg are fixed at the two ends of a light rod of length {sig(d, 3)} m. The centre of mass lies at a distance from the {sig(m1, 3)} kg mass of:",
        strs,
        f"Taking the {sig(m1, 3)} kg mass as origin: x = (m\u2081\u00b70 + m\u2082\u00b7d)/(m\u2081 + m\u2082) = {sig(m2, 3)} \u00d7 {sig(d, 3)}/{sig(m1 + m2, 3)} = {x:.2f} m from the {sig(m1, 3)} kg end. The COM sits CLOSER to the heavier mass.",
        {
            "A": "assumes equal masses (midpoint) \u2014 the masses here differ",
            "C": "measured from the wrong end",
            "D": "multiplied masses together \u2014 no such formula",
        },
        "Medium", "application", None,
    )


TEMPLATES: list[Callable[[], Q]] = [
    t_terminal_voltage, t_stretch_wire, t_series_parallel_ratio, t_shunt_galvanometer,
    t_potentiometer_emf_ratio, t_heat_power_bulbs, t_drift_velocity, t_resistivity_series_rods,
    t_kirchhoff_conservation, t_wheatstone_balance, t_temperature_coefficient,
    t_power_loss_transmission, t_cells_short_circuit, t_potentiometer_internal_resistance,
    t_wire_cut_rejoin, t_capacitor_energy, t_coulomb_force, t_ohm_resistivity_wire,
    t_projectile_range, t_shm_time_period, t_lens_power, t_wave_optics_ydse,
    t_photoelectric_kmax, t_bohr_radius_energy, t_magnetic_field_loop, t_momentum_photon,
    t_gravitation_Weight, t_bernoulli_or_viscosity, t_thermo_efficiency, t_work_energy_spring,
    t_nuclei_half_life, t_emf_induced, t_resolution_telescope, t_ohmic_heating_kettle,
    t_vector_addition, t_relativity_gamma, t_center_of_mass,
]


def generate(count: int) -> list[Q]:
    """Generate `count` questions by cycling templates with fresh parameters."""
    out: list[Q] = []
    per = [count // len(TEMPLATES)] * len(TEMPLATES)
    for i in range(count % len(TEMPLATES)):
        per[i] += 1
    counters = [0] * len(TEMPLATES)
    next_id = 9100
    while any(p > 0 for p in per):
        idx = RNG.randrange(len(TEMPLATES))
        if per[idx] <= 0:
            continue
        per[idx] -= 1
        q = TEMPLATES[idx]()
        q["id"] = f"NEET-{next_id}"
        next_id += 1
        counters[idx] += 1
        out.append(q)
    return out


def selftest() -> None:
    """Run each template 300 times; verify answer distinctness and explanation sanity."""
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
