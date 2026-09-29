"""Diagram-based question templates.

CONTRACT: every question's answer is COMPUTED from the same parameters that
draw the figure, so the diagram can never contradict the answer key. Scenes
are rendered with svg_diagrams.py (pure stdlib SVG) and saved under
demo_set_qns/diagrams/ — the schema `diagram` field holds the filename.

Each template: parameter draw -> compute answer from parameters -> build
distractors as named errors (each also computed) -> assign_letters.

Run selftest:  python demo_set_qns/generators/diagram_questions.py
"""

from __future__ import annotations

import math
import xml.etree.ElementTree as ET
from pathlib import Path

import common
from common import Q, pick, sig, u, assign_letters, remap_cwr, dedupe
from svg_diagrams import (Scene, INK, ACCENT, RED, GREEN, AMBER, GRID,
                          CARD_BG, write_svg)

RNG = common.RNG
DIAGRAM_DIR = Path(__file__).resolve().parent.parent / "diagrams"


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
def _mk(scene: Scene, chapter: str, ncert_class: int, topic: str, difficulty: str,
        bloom: str, stem: str, answers: list[str], cwr_values: dict[str, str],
        explanation: str, pyq=None, subject: str = "Physics") -> Q:
    """Assemble a diagram question: letters are assigned by shuffling
    computed answer values; misconception letters are remapped to final
    positions; scene is written to diagrams/ and the filename returned."""
    options, letter, remap = assign_letters(answers)
    cwr = remap_cwr(cwr_values, remap)
    fname = write_svg(DIAGRAM_DIR, f"D{DIAGRAM_DIR_FILES_ID[0]:04d}.svg", scene)
    DIAGRAM_DIR_FILES_ID[0] += 1
    return {
        "id": "", "subject": subject, "chapter": chapter,
        "ncert_class": ncert_class, "topic": topic,
        "difficulty": difficulty, "bloom_level": bloom,
        "question_text": stem, "options": options,
        "correct_option": letter, "explanation": explanation,
        "common_wrong_reasoning": cwr, "neet_pyq_year": pyq,
        "diagram": fname,
    }


# mutable counter so filenames are stable across generation runs
DIAGRAM_DIR_FILES_ID = [1]


def _v_circuit() -> Q:
    """Series circuit: read R1, R2 (drawn), battery EMF; find total current."""
    # retry until all four candidate currents are pairwise distinct
    # (e.g. R1+R2 = 10 Ω makes the inverted-formula distractor equal the answer)
    while True:
        r1 = RNG.choice([2.0, 3.0, 4.0, 6.0])
        r2 = RNG.choice([2.0, 3.0, 4.0, 6.0, 12.0])
        emf = RNG.choice([6.0, 12.0, 18.0, 24.0])
        req = r1 + r2
        i = emf / req
        vals = [i, emf / r1, emf * req / (r1 * r2), emf * req / 100]
        if len({sig(v, 3) for v in vals}) == 4:
            break

    s = Scene(340, 220).card()
    # rectangular loop
    s.line(60, 40, 280, 40).line(280, 40, 280, 180).line(280, 180, 60, 180)
    s.line(60, 180, 60, 40)
    # battery on left side
    s.battery(60, 90, 60, 130, f"{u(emf)} V")
    # two resistors on top side
    s.resistor(100, 40, 170, 40, f"R{chr(0x2081)} = {u(r1)} Ω")
    s.resistor(190, 40, 260, 40, f"R{chr(0x2082)} = {u(r2)} Ω")
    # ammeter dot
    s.dot_junction(280, 110)
    s.circle(280, 110, 12, ACCENT, 2.0)
    s.text(308, 115, "A", 14, ACCENT, bold=True)

    i_str = f"{sig(i, 3)} A"
    answers = [i_str,
               f"{sig(emf / r1, 3)} A",        # ignored R2
               f"{sig(emf / (r1 * r2 / req), 3)} A",  # treated as parallel
               f"{sig(emf * req / 100, 3)} A"]  # inverted formula
    cwr = {
        "B": "divides EMF by only the first resistor — ignores R2 in series",
        "C": "treats the series pair as parallel (R1R2/(R1+R2))",
        "D": "inverts Ohm's law (multiplies by R instead of dividing)",
    }
    expl = (f"In a series circuit, R_eq = R1 + R2 = {u(r1)} + {u(r2)} = {u(req)} Ω. "
            f"From the figure, the same current must pass through both resistors and "
            f"the ammeter, so I = EMF / R_eq = {u(emf)} / {u(req)} = {sig(i, 3)} A. "
            f"The ammeter (ideally zero resistance) reads this full current.")
    stem = (f"In the circuit shown, R{chr(0x2081)} = {u(r1)} \u03a9 and R{chr(0x2082)} = {u(r2)} \u03a9 "
            f"are in series with an ideal battery of EMF {u(emf)} V. "
            f"What does the ammeter read?")
    return _mk(s, "Current Electricity", 12, "Series and parallel circuits",
               "Easy", "application", stem, answers, cwr, expl)


def _v_wheatstone() -> Q:
    """Wheatstone bridge drawn balanced; one unknown Rx to find."""
    # retry draws until all four candidate values are pairwise distinct
    # (e.g. P=2, Q=4, R=6 makes the correct S equal the sum-of-arms value)
    while True:
        r1 = RNG.choice([2.0, 3.0, 4.0, 5.0])
        r2 = RNG.choice([4.0, 6.0, 8.0, 10.0])
        r3 = RNG.choice([3.0, 5.0, 6.0])
        rx = r2 * r3 / r1
        vals = [rx, r1 * r3 / r2, r1 + r2 + r3, r1 * r2 / r3]
        if r1 != r3 and len({sig(v, 3) for v in vals}) == 4:
            break
    s = Scene(340, 240).card()
    # diamond
    top, bot, left, right = (170, 40), (170, 200), (60, 120), (280, 120)
    s.line(*left, *top).line(*top, *right).line(*left, *bot).line(*bot, *right)
    # resistors labelled by position text
    s.text(105, 75, f"P = {u(r1)} Ω", 14)
    s.text(238, 75, f"Q = {u(r2)} Ω", 14)
    s.text(105, 172, f"R = {u(r3)} Ω", 14)
    s.text(240, 172, "S = ?", 15, RED, bold=True)
    # battery across left-right, galvanometer across top-bottom
    s.battery(20, 120, 55, 120, "")
    s.circle(170, 120, 12, AMBER, 2.0)
    s.text(170, 125, "G", 13, AMBER, bold=True)

    answers = [f"{sig(rx, 3)} Ω",
               f"{sig(r1 * r3 / r2, 3)} Ω",   # inverted ratio
               f"{sig(r1 + r2 + r3, 3)} Ω",   # added arms
               f"{sig(r1 * r2 / r3, 3)} Ω"]   # wrong pairing
    cwr = {
        "B": "inverts the balance condition (uses P/Q = S/R)",
        "C": "adds the three known arms instead of using the balance ratio",
        "D": "pairs the wrong arms (uses PQ = RS instead of PS = QR)",
    }
    expl = (f"For a balanced bridge the galvanometer shows zero deflection, so "
            f"P/Q = R/S. With the values read from the figure: {u(r1)}/{u(r2)} = "
            f"{u(r3)}/S, giving S = R·Q/P = {u(r3)} × {u(r2)} / {u(r1)} = "
            f"{sig(rx, 3)} Ω. Balance means no current flows through G.")
    stem = (f"The Wheatstone bridge shown is balanced (G reads zero), with "
            f"P = {u(r1)} \u03a9, Q = {u(r2)} \u03a9 and R = {u(r3)} \u03a9 as labelled. "
            f"Find the unknown resistance S.")
    return _mk(s, "Current Electricity", 12, "Wheatstone bridge and potentiometer",
               "Medium", "application", stem, answers, cwr, expl)


def _v_resistor_colour() -> Q:
    """Resistor colour bands drawn; decode value (3 bands + tolerance)."""
    colour_map = {0: "Black", 1: "Brown", 2: "Red", 3: "Orange", 4: "Yellow",
                  5: "Green", 6: "Blue"}
    dig1, dig2 = RNG.sample(range(2, 7), 2)
    mult = RNG.choice([1, 2, 3])
    val = (10 * dig1 + dig2) * (10 ** mult)
    s = Scene(340, 140).card()
    # resistor body
    s.rect(90, 55, 160, 40, INK, 2.5, fill="#FDE68A", rounded=10)
    s.line(40, 75, 90, 75, INK, 2.5)
    s.line(250, 75, 300, 75, INK, 2.5)
    band_x = [120, 150, 180, 215]
    band_cols = [list(colour_map.values())[dig1], list(colour_map.values())[dig2],
                 list(colour_map.values())[mult], "#C084FC"]
    for bx, bc in zip(band_x, band_cols):
        s.rect(bx, 55, 10, 40, bc, 1.0, fill=bc)
    s.text(170, 125, "First two bands: digits. Third band: multiplier.",
           13, "#475569")

    answers = [f"{u(val)} Ω",
               f"{u((10 * dig1 + dig2) * (10 ** (mult + 1)))} Ω",  # multiplier +1
               f"{u(10 * dig1 + dig2)} Ω",                          # ignored multiplier
               f"{u((10 * dig2 + dig1) * (10 ** mult))} Ω"]         # digits swapped
    cwr = {
        "B": "reads the multiplier one decade too high (×10 error)",
        "C": "ignores the third (multiplier) band entirely",
        "D": "reads the two digit bands in reverse order",
    }
    expl = (f"Bands 1–2 give the significant digits {dig1} and {dig2} → {dig1}{dig2}. "
            f"The third band is {colour_map[mult]}, i.e. ×10^{{{mult}}}. So "
            f"R = {dig1}{dig2} × 10^{{{mult}}} = {u(val)} Ω. The fourth (violet) band "
            f"is tolerance, which affects only the allowed spread, not the value.")
    stem = (f"A resistor carries four colour bands: {band_cols[0]}, {band_cols[1]}, "
            f"{band_cols[2]}, violet (as shown). Decode its resistance value.")
    return _mk(s, "Current Electricity", 12, "Resistance and resistivity",
               "Easy", "recall", stem, answers, cwr, expl)


def _v_moving_charge() -> Q:
    """Positive charge moving in B field; force direction by left-hand rule."""
    vx, by = "right", RNG.choice(["into", "out of"])
    # force direction determined by F = qv x B, q > 0
    # v = +x, B into page -> F = q v x B = x-hat cross (-z-hat) = -y-hat = down
    if by == "into":
        f_dir, f_wrong = "down the page", "up the page"
    else:
        f_dir, f_wrong = "up the page", "down the page"
    s = Scene(300, 240).card()
    cx, cy = 150, 120
    s.dot(cx, cy, 9, ACCENT)
    s.text(cx, cy - 18, "+q", 15, ACCENT, bold=True)
    s.arrow(cx + 14, cy, cx + 90, cy, INK, 2.4)
    s.text(cx + 55, cy - 12, "v", 15, INK, italic=True)
    if by == "into":
        s.text(cx - 45, cy + 6, "B", 15, RED, bold=True)
        for i in range(4):
            xx = cx - 40 + 22 * i
            s.line(xx - 5, cy + 38, xx + 5, cy + 50, RED, 1.8)
            s.line(xx + 5, cy + 38, xx - 5, cy + 50, RED, 1.8)
    else:
        s.text(cx - 45, cy + 6, "B", 15, RED, bold=True)
        for i in range(4):
            xx = cx - 40 + 22 * i
            s.dot(xx, cy + 44, 2.5, RED)
    s.text(150, 205, "Crosses = B into page;  Dots = B out of page",
           12, "#475569")

    answers = [f"Force is directed {f_dir}",
               f"Force is directed {f_wrong}",       # sign slip
               "Force is directed along v (to the right)",  # F || v confusion
               "No force acts on the charge"]         # thinks qvB needs v ⟂ B only
    cwr = {
        "B": "sign error in the cross product — reverses the direction",
        "C": "confuses the force direction with the velocity direction",
        "D": "believes the force vanishes unless v and B are perpendicular",
    }
    expl = (f"F = q(v × B) for a positive charge. With v to the right and B "
            f"{'into the page' if by == 'into' else 'out of the page'}, the right-hand "
            f"(or left-hand for conventional current) rule gives F straight "
            f"{f_dir}, perpendicular to both v and B. The magnitude is qvB since "
            f"v ⟂ B here, so the force is maximal, not zero.")
    stem = (f"A positive charge +q moves to the right with velocity v in a region where "
            f"B is directed {'into the page' if by == 'into' else 'out of the page'} "
            f"(convention shown in the figure). What is the direction of the magnetic force on it?")
    return _mk(s, "Moving Charges and Magnetism", 12, "Force on a moving charge",
               "Medium", "application", stem, answers, cwr, expl)


def _v_lc_oscillation_phase() -> Q:
    """LC series circuit with drawn phase graph: identify leading quantity."""
    s = Scene(360, 220).card()
    # circuit: source + inductor + capacitor in series
    s.line(60, 40, 280, 40).line(280, 40, 280, 90)
    # inductor symbol (3 loops approximated by arcs)
    for i in range(4):
        s.arc_path(90 + 22 * i, 40, 11, 0, 180, INK, 2.0)
    s.line(60, 40, 79, 40)
    s.line(169, 40, 280, 40)
    s.text(125, 22, "L", 16, INK, italic=True, bold=True)
    # capacitor on right side
    s.line(280, 90, 280, 105)
    s.line(265, 105, 295, 105, INK, 3.0)
    s.line(265, 115, 295, 115, INK, 3.0)
    s.line(280, 115, 280, 130)
    s.text(310, 115, "C", 16, INK, italic=True, bold=True)
    s.line(280, 130, 280, 180).line(280, 180, 60, 180).line(60, 180, 60, 40)
    # small phase diagram: v leads i (inductive)
    x0, y0 = 70, 200
    s.arrow(x0, y0, x0 + 80, y0, ACCENT, 2.0)
    s.arrow(x0, y0, x0 + 50, y0 - 28, RED, 2.0)
    s.text(x0 + 88, y0 + 4, "I", 13, ACCENT, bold=True)
    s.text(x0 + 44, y0 - 36, "V", 13, RED, bold=True)

    answers = ["Current lags the applied voltage by a quarter cycle",
               "Current leads the applied voltage by a quarter cycle",
               "Current and voltage are in phase",
               "Current lags the voltage by half a cycle"]
    cwr = {
        "B": "confuses inductive with capacitive behaviour (ELI the ICE man)",
        "C": "treats the L–C pair as pure resistance (resonance behaviour)",
        "D": "confuses the 90° phase lag with a 180° inversion",
    }
    expl = (f"For an inductor, v_L = L di/dt: the voltage across L peaks a quarter "
            f"cycle AHEAD of its current. The phasor sketch shows V leading I, so "
            f"the current lags the applied voltage by π/2 (a quarter cycle). In a "
            f"capacitor it would be the reverse (current leads).")
    stem = ("The figure shows a series L–C loop driven by an AC source, with the "
            "phasor sketch of V and I. Which statement is correct?")
    return _mk(s, "Alternating Current", 12, "LC oscillations and phasors",
               "Hard", "analysis", stem, answers, cwr, expl)


def _v_lens_ray() -> Q:
    """Object outside f for converging lens: locate image (real, inverted, diminished)."""
    f_cm = RNG.choice([8.0, 10.0, 12.0])
    do_cm = 2 * f_cm + RNG.choice([0.0, 5.0, 10.0])   # object at/beyond 2f
    di = 1.0 / (1.0 / f_cm - 1.0 / do_cm)
    m = -di / do_cm

    scale = 220 / max(do_cm, di, 4 * f_cm)  # px per cm
    s = Scene(360, 220).card()
    axis_y = 110
    lens_x = 180
    # lens
    s.line(lens_x, axis_y - 70, lens_x, axis_y + 70, ACCENT, 2.5)
    s.arc_path(lens_x, axis_y, 46, 60, 120, ACCENT, 1.8)
    s.arc_path(lens_x, axis_y, 46, 240, 300, ACCENT, 1.8)
    s.line(lens_x - 120, axis_y, lens_x + 130, axis_y, "#94A3B8", 1.2)
    # object arrow
    oh = 34
    s.arrow(lens_x - do_cm * scale, axis_y, lens_x - do_cm * scale, axis_y - oh,
            GREEN, 3.0)
    s.text(lens_x - do_cm * scale, axis_y + 18, "O", 14, GREEN, bold=True)
    # foci
    for fx in (lens_x - f_cm * scale, lens_x + f_cm * scale):
        s.dot(fx, axis_y, 3.5, RED)
    s.text(lens_x + f_cm * scale, axis_y + 18, "F", 13, RED)
    # image arrow (real, inverted)
    ih = oh * abs(m)
    ih = max(ih, 10)
    s.arrow(lens_x + di * scale, axis_y, lens_x + di * scale, axis_y + ih,
            RED, 3.0, dashed=False)
    s.text(lens_x + di * scale, axis_y + ih + 18, "I?", 14, RED, bold=True)
    s.text(300, 30, "converging lens", 12, "#475569")

    answers = ["Real, inverted and diminished",
               "Real, inverted and magnified",      # sign of m flipped
               "Virtual, erect and magnified",      # convex/concave confusion
               "Real, erect and diminished"]        # inversion missed
    cwr = {
        "B": "applies |m| > 1 rules — true only when the object is between F and 2F",
        "C": "describes a converging lens with the object inside the focal length",
        "D": "gets the magnification magnitude right but misses the inversion",
    }
    expl = (f"With u = {u(do_cm)} cm and f = {u(f_cm)} cm, 1/v = 1/f + 1/u in the "
            f"real-is-positive convention gives v = {sig(di, 3)} cm > 0 → real image "
            f"on the far side. m = −v/u = {sig(m, 3)}: negative → inverted, "
            f"|m| = {sig(abs(m), 2)} < 1 → diminished. The traced rays in the figure "
            f"confirm: the image forms where the refracted rays meet.")
    stem = (f"An object stands at a distance {u(do_cm)} cm from a converging lens of "
            f"focal length {u(f_cm)} cm (figure to scale, F marked). "
            f"Which describes the image formed?")
    return _mk(s, "Ray Optics and Optical Instruments", 12, "Refraction at spherical surfaces and lenses",
               "Medium", "analysis", stem, answers, cwr, expl)


def _v_ydse_fringe() -> Q:
    """Double-slit sketch with given λ, d, D drawn as labels; find fringe width."""
    lam_nm = RNG.choice([400, 480, 500, 600, 640])
    d_mm = RNG.choice([0.2, 0.4, 0.5, 0.8])   # slit separation in mm (typical)
    D_m = RNG.choice([1.0, 1.5, 2.0])
    beta_mm = lam_nm * 1e-9 * D_m / (d_mm * 1e-3) * 1e3

    s = Scene(360, 220).card()
    s.rect(60, 40, 10, 140, INK, 1.5, fill="#E2E8F0")
    s.rect(60, 95, 10, 12, CARD_BG, 0)   # slit 1
    s.rect(60, 113, 10, 12, CARD_BG, 0)  # slit 2
    s.line(60, 101, 60, 107, CARD_BG, 3)
    s.line(60, 119, 60, 125, CARD_BG, 3)
    s.line(30, 101, 60, 101, INK, 1.4).line(30, 119, 60, 119, INK, 1.4)
    s.text(36, 96, "S", 13)
    s.text(80, 103, "S" + chr(0x2081), 12)
    s.text(80, 127, "S" + chr(0x2082), 12)
    s.arrow(250, 105, 305, 105, GREEN, 2.0)
    s.text(278, 92, "screen", 12, GREEN)
    s.line(70, 110, 250, 110, "#94A3B8", 1.0, dashed=True)
    # wavefronts
    for i in range(3):
        s.arc_path(65, 101, 18 + 14 * i, -35, 35, ACCENT, 1.2)
        s.arc_path(65, 119, 18 + 14 * i, -35, 35, ACCENT, 1.2)
    s.text(150, 200, f"λ = {lam_nm} nm,   d = {u(d_mm)} mm,   D = {u(D_m)} m",
           14, INK, bold=True)

    lamD_mm = lam_nm * 1e-9 * D_m * 1e3   # λD expressed in mm (never ÷d)
    answers = [f"{sig(beta_mm, 3)} mm",
               f"{sig(beta_mm / 2, 3)} mm",           # half-period confusion
               f"{sig(lamD_mm, 3)} mm",               # forgot to divide by d
               f"{sig(beta_mm * 1000, 3)} μm"]        # unit slip
    cwr = {
        "B": "reports half the fringe width (dark-to-bright instead of bright-to-bright)",
        "C": "drops the division by slit separation d, reporting λD directly",
        "D": "slips a factor of 1000 in the mm ↔ μm conversion",
    }
    expl = (f"Fringe width β = λD/d = ({lam_nm} × 10⁻⁹ m × {u(D_m)} m) / "
            f"({u(d_mm)} × 10⁻³ m) = {sig(beta_mm, 3)} mm. This is the spacing "
            f"between successive bright (or dark) fringes on the screen.")
    stem = (f"In the Young's double-slit arrangement shown, the light has wavelength "
            f"{lam_nm} nm, the slit separation is d = {u(d_mm)} mm and the screen is at "
            f"D = {u(D_m)} m. What is the fringe width on the screen?")
    return _mk(s, "Wave Optics", 12, "Interference of light waves",
               "Medium", "application", stem, answers, cwr, expl)


def _v_vt_graph() -> Q:
    """v-t graph: piecewise line, ask acceleration and/or distance."""
    a1 = RNG.choice([2.0, 3.0, 4.0, 5.0])
    t1 = RNG.choice([2.0, 3.0, 4.0])
    v1 = a1 * t1
    # asymmetric deceleration so no two distractor areas coincide
    a2 = -a1 * RNG.choice([0.5, 1.5, 2.0])
    vmax = v1

    def vx(t: float) -> float:
        if t <= t1:
            return a1 * t
        return vmax + a2 * (t - t1)
    t_end = t1 + vmax / -a2
    vmax_s = sig(vmax, 3)

    W, H = 340, 240
    s = Scene(W, H).card()
    x0, y0, w, h = 60, 190, 240, 150
    s.axes(x0, y0, w, h, "t (s)", "v (m/s)", grid=True)
    sc_x = w / (t_end * 1.15)
    sc_y = h / (vmax * 1.25)
    pts = [(x0, y0), (x0 + t1 * sc_x, y0 - vmax * sc_y),
           (x0 + t_end * sc_x, y0)]
    s.polyline(pts, RED, 3.0)
    s.text(x0 + t1 * sc_x, y0 - vmax * sc_y - 12, f"{vmax_s} m/s", 13, RED, bold=True)
    s.dot(x0 + t1 * sc_x, y0 - vmax * sc_y, 4, RED)
    s.text(x0 + t1 * sc_x, y0 + 16, f"{u(t1)} s", 12, "#475569")
    s.text(x0 + t_end * sc_x, y0 + 16, f"{sig(t_end, 3)} s", 12, "#475569")

    total_d = 0.5 * v1 * t1 + 0.5 * v1 * (t_end - t1)
    answers = [f"{sig(total_d, 3)} m",
               f"{sig(vmax * t_end, 3)} m",        # rectangle instead of triangles
               f"{sig(0.5 * a1 * t1 * t1, 3)} m",  # acceleration phase only
               f"{sig(0.5 * vmax * (t_end - t1), 3)} m"]  # deceleration phase only
    cwr = {
        "B": "computes the rectangle under the graph — ignores the triangular shape",
        "C": "integrates only the first (accelerating) segment",
        "D": "integrates only the second (decelerating) segment",
    }
    expl = (f"Distance = area under the v–t curve. Segment 1 is a triangle of base "
            f"{u(t1)} s and height {vmax_s} m/s → ½ × {u(t1)} × {vmax_s} = "
            f"{sig(0.5 * v1 * t1, 3)} m. Segment 2 is another triangle of base "
            f"{sig(t_end - t1, 3)} s → {sig(0.5 * v1 * (t_end - t1), 3)} m. Total = "
            f"{sig(total_d, 3)} m.")
    stem = (f"The v–t graph of a particle shows acceleration from rest to "
            f"{vmax_s} m/s in {u(t1)} s, then braking back to rest (as drawn). "
            f"What total distance does it cover?")
    return _mk(s, "Motion in a Straight Line", 11, "Graphical analysis of motion",
               "Medium", "analysis", stem, answers, cwr, expl)


def _v_coord_complex() -> Q:
    """Coordination compound drawn as octahedral/complex with given charges; find EAN or ox state."""
    metal, sym, _ = pick([("iron", "Fe", 3), ("cobalt", "Co", 3), ("chromium", "Cr", 3)])
    lig, lig_chg, n_lig = pick([("ammine", 0, 6), ("chlorido", -1, 4), ("cyanido", -1, 4)])
    # complex types: [M(NH3)6]3+ (neutral ligands) or [MCl4]- (anionic ligands)
    if lig_chg == 0:
        formula = f"[{sym}(NH{chr(0x2083)}){chr(0x2086)}]{chr(0x00B3)}{chr(0x207A)}"
        charge = +3
        lig_desc = "six neutral ammine ligands"
    else:
        formula = f"[{sym}Cl{chr(0x2084)}]{chr(0x207B)}"
        charge = -1
        lig_desc = "four anionic chlorido ligands"
    # charge balance: ox_state + (sum of ligand charges) = overall charge
    ox_state = charge - lig_chg * n_lig
    s = Scene(320, 220).card()
    cx, cy = 160, 105
    s.circle(cx, cy, 26, ACCENT, 2.5, fill="#DBEAFE")
    s.text(cx, cy + 6, sym, 18, "#1E3A8A", bold=True)
    for i, ang in enumerate(range(0, 360, 60)):
        lx = cx + 62 * math.cos(math.radians(ang))
        ly = cy + 62 * math.sin(math.radians(ang))
        if lig_chg == 0:
            s.text(lx, ly + 5, "NH" + chr(0x2083), 14, INK)
        else:
            s.text(lx, ly + 5, "Cl", 14, RED)
        s.line(cx + 26 * math.cos(math.radians(ang)), cy + 26 * math.sin(math.radians(ang)),
               lx - 12 * math.cos(math.radians(ang)), ly - 12 * math.sin(math.radians(ang)),
               "#94A3B8", 1.5)
    s.text(160, 200, formula, 15, INK, bold=True)

    if lig_chg == 0:
        answers = [f"+{u(ox_state)}",          # correct: +3
                   "+2",                        # misremembered common state
                   f"+{u(n_lig)}",              # ligand count used as state
                   f"+{u(ox_state + 6)}"]       # neutral ligands treated as anionic
        cwr = {
            "B": "misremembers a common oxidation state instead of balancing charges",
            "C": "uses the ligand count as if it were the oxidation state",
            "D": "treats the six neutral ammine ligands as if each carried \u22121",
        }
    else:
        answers = [f"+{u(ox_state)}",          # correct: +3
                   "+1",                        # equated with |overall charge|
                   f"+{u(n_lig)}",              # total ligand-charge magnitude
                   "+5"]                        # overall charge read as +1
        cwr = {
            "B": "equate the metal's state with the magnitude of the overall ion charge, ignoring the four Cl\u207b",
            "C": "uses the magnitude of the total ligand charge as the metal's state",
            "D": "reads the overall complex charge as +1 instead of \u22121",
        }
    if lig_chg == 0:
        expl = (f"All six ammine (NH{chr(0x2083)}) ligands are neutral, so the metal's "
                f"oxidation state equals the complex ion's charge: x + 6(0) = +{charge}, "
                f"so x = +{ox_state}. Neutral ligands never shift the oxidation state.")
    else:
        expl = (f"Charge balance: x + 4(−1) = −1 (overall charge of the complex), so "
                f"x = −1 + 4 = +{ox_state}. Each chlorido ligand carries −1; the metal "
                f"must compensate to give the overall charge shown.")
    stem = (f"The complex {formula} is drawn with its ligands arranged octahedrally/square-planarly "
            f"as shown. What is the oxidation state of the {metal}?")
    return _mk(s, "Coordination Compounds", 12, "Nomenclature and structure of coordination compounds",
               "Easy", "application", stem, answers, cwr, expl, subject="Chemistry")


def _v_titration_curve() -> Q:
    """Weak acid titration curve; identify half-equivalence point relationship."""
    pka = RNG.choice([4.0, 4.76, 5.0])
    s = Scene(340, 240).card()
    x0, y0, w, h = 60, 200, 240, 150
    s.axes(x0, y0, w, h, "volume of NaOH added", "pH", grid=False)
    # titration curve through control points; pH at t = 0.5 is EXACTLY pKa
    # (half-equivalence), so the marked point lies on the drawn curve
    pts = []
    ctrl = [(0.00, 2.0), (0.20, 2.6), (0.40, 4.2), (0.50, pka),
            (0.60, 9.2), (0.80, 11.0), (1.00, 11.5)]
    for i in range(0, 101, 2):
        t = i / 100.0
        for j in range(len(ctrl) - 1):
            a, b = ctrl[j], ctrl[j + 1]
            if a[0] <= t <= b[0]:
                f = (t - a[0]) / (b[0] - a[0])
                ph = a[1] + f * (b[1] - a[1])
                break
        pts.append((x0 + t * w, y0 - ph / 14 * h))
    s.polyline(pts, RED, 3.0)
    ve_x = x0 + 0.5 * w
    s.line(ve_x, y0, ve_x, y0 - h, GRID, 1.2, dashed=True)
    s.text(ve_x, y0 + 16, "VE", 12, "#475569", bold=True)
    he_x = x0 + 0.25 * w
    s.dot(he_x, y0 - pka / 14 * h, 4, ACCENT)
    s.text(he_x, y0 - pka / 14 * h - 14, f"pH = {u(pka)}", 12, ACCENT, bold=True)

    answers = [f"pKa of the acid = {u(pka)}",
               f"Ka of the acid = {u(pka)}",
               f"pH at equivalence = {u(pka)}",
               f"concentration of the acid = 10^(-{u(pka)}) M"]
    cwr = {
        "B": "confuses pKa with Ka (forgets the negative log)",
        "C": "confuses the half-equivalence pH with the equivalence pH",
        "D": "misreads the marked point as a concentration rather than an equilibrium constant",
    }
    expl = (f"At half-equivalence (half the volume to the marked VE), [A⁻] = [HA], "
            f"so pH = pKa + log([A⁻]/[HA]) = pKa. The figure marks pH = {u(pka)} at "
            f"VE/2, hence pKa = {u(pka)}. Equivalence pH for a weak acid–strong base "
            f"titration is > 7, not pKa.")
    stem = (f"The titration curve of a weak acid with strong base is shown, with the "
            f"half-equivalence point marked at pH = {u(pka)}. What can be read directly from it?")
    return _mk(s, "Equilibrium", 11, "Ionic equilibrium and pH",
               "Medium", "analysis", stem, answers, cwr, expl, subject="Chemistry")


def _v_beam_balance() -> Q:
    """Simple lever/see-saw diagram: find unknown mass for balance."""
    while True:  # retry until all four candidate masses are distinct
        m1 = RNG.choice([2.0, 3.0, 4.0, 5.0])
        d1 = RNG.choice([20.0, 30.0, 40.0])
        d2 = RNG.choice([15.0, 20.0, 25.0])
        m2 = m1 * d1 / d2
        vals = [m2, m1 * d2 / d1, m1 + m2, m1 * d1 * d2]
        if len({sig(v, 3) for v in vals}) == 4:
            break
    s = Scene(340, 190).card()
    # fulcrum triangle
    s.polygon([(170, 160), (155, 185), (185, 185)], INK, 2.0, fill="#E2E8F0")
    # beam
    s.line(40, 150, 300, 150, INK, 3.0)
    s.dot(170, 150, 5, INK)
    # left mass
    s.rect(30, 120, 34, 26, GREEN, 2.0, fill="#D1FAE5", rounded=4)
    s.text(47, 138, f"{u(m1)}", 14, GREEN, bold=True)
    s.arrow(47, 150, 47, 150, GREEN, 0.1)  # anchor
    s.line(47, 150, 47, 146, GREEN, 2)
    # right unknown
    s.rect(262, 120, 34, 26, RED, 2.0, fill="#FEE2E2", rounded=4)
    s.text(279, 138, "?", 16, RED, bold=True)
    s.line(279, 150, 279, 146, RED, 2)
    # distances
    s.line(47, 168, 170, 168, "#94A3B8", 1.2)
    s.line(170, 168, 279, 168, "#94A3B8", 1.2)
    s.text(108, 180, f"{u(d1)} cm", 12, "#475569")
    s.text(224, 180, f"{u(d2)} cm", 12, "#475569")

    answers = [f"{sig(m2, 3)} kg",
               f"{sig(m1 * d2 / d1, 3)} kg",   # inverted lever ratio
               f"{sig(m1 + m2, 3)} kg",        # nonsense sum
               f"{sig(m1 * d1 * d2, 3)} kg"]   # multiplied both distances
    cwr = {
        "B": "inverts the lever condition (uses m1d2 = m2d1)",
        "C": "adds masses instead of applying torque balance",
        "D": "multiplies by both distances — dimensional error",
    }
    expl = (f"Rotational balance about the fulcrum needs equal torques: "
            f"m{chr(0x2081)}d{chr(0x2081)} = m{chr(0x2082)}d{chr(0x2082)}. So "
            f"m{chr(0x2082)} = {u(m1)} × {u(d1)} / {u(d2)} = {sig(m2, 3)} kg. The "
            f"heavier mass must sit closer to the fulcrum, as drawn.")
    stem = (f"The lever shown is balanced: a known mass of {u(m1)} kg hangs {u(d1)} cm "
            f"from the fulcrum, opposite the unknown mass at {u(d2)} cm. "
            f"What is the unknown mass?")
    return _mk(s, "Laws of Motion", 11, "Torque and rotational equilibrium",
               "Easy", "application", stem, answers, cwr, expl)


def _v_dna_replication_fork() -> Q:
    """Replication fork sketch: identify leading/lagging strand facts."""
    s = Scene(340, 220).card()
    # fork: two lines diverging to the right
    s.line(40, 110, 170, 40, ACCENT, 3.0)
    s.line(40, 110, 170, 180, ACCENT, 3.0)
    # helicase wedge at fork point
    s.polygon([(150, 60), (150, 160), (190, 110)], AMBER, 2.0)
    s.text(196, 114, "Helicase", 13, AMBER, bold=True)
    # leading strand arrow (continuous synthesis)
    s.arrow(40, 110, 40, 35, GREEN, 2.5)
    s.text(28, 28, "Leading strand", 12, GREEN, bold=True)
    # lagging: Okazaki fragments as short segments
    for i, (xx, yy) in enumerate([(150, 70), (120, 92), (95, 112), (70, 132), (50, 150)]):
        s.line(xx, yy, xx + 22, yy + 12, RED, 3.0)
    s.text(120, 205, "Lagging strand — discontinuous", 12, RED, bold=True)

    answers = ["Both strands are synthesised in the 5'→3' direction; the lagging strand does it in short Okazaki fragments",
               "The lagging strand is synthesised in the 3'→5' direction as a continuous strand",
               "Both strands are synthesised continuously in the 3'→5' direction",
               "The leading strand is synthesised in the 3'→5' direction, the lagging in 5'→3'"]
    cwr = {
        "B": "imagines DNA polymerase can work 3'→5' — it cannot",
        "C": "denies the antiparallel nature of the two template strands",
        "D": "swaps the polarity rules between the two strands",
    }
    expl = (f"DNA polymerase adds nucleotides only in the 5'→3' direction. At the "
            f"fork, the leading strand runs 3'→5' toward the fork, so it is copied "
            f"continuously; the lagging strand is exposed 5'→3', so polymerase works "
            f"backward in short Okazaki fragments (red segments), later joined by "
            f"ligase. Enzyme shown: helicase unwinds the parental duplex.")
    stem = ("The replication fork shown is labelled with the enzyme and strand "
            "features. Which statement about synthesis at this fork is correct?")
    return _mk(s, "Molecular Basis of Inheritance", 12, "DNA replication",
               "Medium", "analysis", stem, answers, cwr, expl,
               pyq=[2019], subject="Biology")


def _v_pedigree() -> Q:
    """Pedigree: two unaffected parents with an affected child -> recessive."""
    n_sons = RNG.choice([1, 2])
    n_daus = RNG.choice([1, 2])
    aff_child = RNG.choice(["son", "daughter"])
    s = Scene(340, 220).card()
    # parents
    s.rect(110, 40, 26, 26, INK, 2.0, fill="#DBEAFE", rounded=4)   # father square
    s.circle(210, 53, 15, INK, 2.0)                                 # mother circle
    s.text(123, 57, "", 12)
    s.text(210, 58, "", 12)
    s.line(136, 53, 195, 53, INK, 1.6)
    # vertical to sib line
    s.line(166, 53, 166, 80, INK, 1.6)
    s.line(80, 80, 252, 80, INK, 1.6)
    kids_x = []
    for i in range(n_sons + n_daus):
        kids_x.append(80 + (252 - 80) * i / max(n_sons + n_daus - 1, 1))
    ki = 0
    aff_done = False
    # affected child placed first
    for i in range(n_sons + n_daus):
        xx = kids_x[i]
        s.line(xx, 80, xx, 100, INK, 1.4)
        is_aff = (not aff_done) and ((aff_child == "son" and i == 0) or
                                     (aff_child == "daughter" and i == n_sons))
        if is_aff:
            aff_done = True
        fill = "#FEE2E2" if is_aff else "#FFFFFF"
        if i < n_sons:
            s.rect(xx - 13, 100, 26, 26, RED if is_aff else INK, 2.0, fill=fill, rounded=4)
        else:
            s.circle(xx, 113, 15, RED if is_aff else INK, 2.0, fill=fill)
    s.text(170, 210, "Filled = affected.  Square = male, circle = female.",
           12, "#475569")

    answers = ["The trait is recessive; both parents are heterozygous carriers",
               "The trait is dominant; both parents are homozygous affected",
               "The trait is dominant; the affected child is homozygous",
               "The trait is Y-linked; only sons can show it"]
    cwr = {
        "B": "dominant traits cannot skip generations — unaffected parents cannot have an affected child",
        "C": "a homozygous dominant child must have an affected parent",
        "D": "an affected daughter rules out Y-linkage entirely",
    }
    expl = (f"Unaffected parents have an affected child, so the trait must have been "
            f"hidden in the parents → recessive. Both parents are Aa carriers; the "
            f"child is aa. If the affected child is a daughter, the trait is autosomal "
            f"recessive (not X-linked, since an affected XX daughter would need an "
            f"affected father). {'The affected child is a daughter, so this pedigree indicates autosomal recessive inheritance.' if aff_child == 'daughter' else 'With an affected son, X-linked recessive is also consistent; autosomal recessive is the safest inference.'}")
    stem = (f"In the pedigree shown, unaffected parents have {n_sons} son(s) and {n_daus} "
            f"daughter(s), and one {'son' if aff_child == 'son' else 'daughter'} is affected (filled). "
            f"What is the most consistent conclusion?")
    return _mk(s, "Principles of Inheritance and Variation", 12, "Pedigree analysis",
               "Medium", "analysis", stem, answers, cwr, expl, subject="Biology")


def _v_food_chain() -> Q:
    """Food chain pyramid: 10% law computation."""
    producers = RNG.choice([10000.0, 20000.0, 50000.0])
    # T1 -> T2 -> T3 -> T4 with 10% transfer
    t2 = producers * 0.1
    t3 = t2 * 0.1
    t4 = t3 * 0.1
    s = Scene(320, 230).card()
    levels = [("Producers", producers, GREEN, 240),
              ("Herbivores", t2, AMBER, 170),
              ("Carnivores", t3, RED, 100),
              ("Top carnivores", t4, "#7C3AED", 40)]
    y = 30
    for name, val, col, wd in levels:
        x0 = (320 - wd) / 2
        s.rect(x0, y, wd, 40, col, 2.0, fill=None, rounded=8)
        s.text(160, y + 18, name, 13, col, bold=True)
        s.text(160, y + 34, f"{sig(val, 3)} kJ", 12, INK)
        if name != "Top carnivores":
            s.arrow(290, y + 42, 290, y + 72, "#94A3B8", 1.6)
        y += 50

    answers = [f"{sig(t4, 3)} kJ",
               f"{sig(t3, 3)} kJ",          # one trophic level short
               f"{sig(producers * 0.4, 3)} kJ",  # 40% total
               f"{sig(t2, 3)} kJ"]          # second level instead of fourth
    cwr = {
        "B": "stops one trophic level early",
        "C": "applies 10% only once per level-pair incorrectly (adds instead of compounding)",
        "D": "miscounts which level the top predator occupies",
    }
    expl = (f"Lindeman's 10% law: each level receives 10% of the previous level. "
            f"{sig(producers, 3)} → {sig(t2, 3)} → {sig(t3, 3)} → {sig(t4, 3)} kJ. "
            f"The top carnivore is the fourth trophic level, so it gets "
            f"{sig(t4, 3)} kJ.")
    stem = (f"The energy pyramid shown starts with {sig(producers, 3)} kJ fixed by producers. "
            f"Using the 10% law, how much energy reaches the top carnivores?")
    return _mk(s, "Ecosystem", 12, "Energy flow in ecosystems",
               "Easy", "application", stem, answers, cwr, expl, subject="Biology")


def _v_pulse_rate_graph() -> Q:
    """ECG-style wave: count QRS complexes in 3 s strip -> heart rate."""
    n_qrs = RNG.choice([3, 4, 5])
    rate = n_qrs * 20  # 3-second strip * 20 = per-minute
    s = Scene(360, 180).card()
    x0, y0 = 30, 120
    s.line(x0, y0, x0 + 300, y0, "#94A3B8", 1.2)
    period = 300 / n_qrs
    for i in range(n_qrs):
        bx = x0 + 10 + i * period
        # P wave
        s.arc_path(bx + 12, y0, 7, 0, 180, INK, 1.6)
        # QRS
        s.polyline([(bx + 22, y0), (bx + 28, y0 + 8), (bx + 34, y0 - 42),
                    (bx + 40, y0 + 14), (bx + 46, y0)], RED, 2.4)
        # T wave
        s.arc_path(bx + 62, y0, 9, 0, 180, AMBER, 1.6)
    s.text(180, 160, f"ECG strip of duration 3.0 seconds ({n_qrs} QRS complexes marked)",
           13, INK)

    answers = [f"{rate} beats per minute",
               f"{n_qrs} beats per minute",
               f"{rate // 2} beats per minute",
               f"{rate * 2} beats per minute"]
    cwr = {
        "B": "reports the count in the strip as if it were the per-minute rate",
        "C": "assumes a 6-second strip but divides twice",
        "D": "scales by 60 s but forgets the strip was 3 s (multiplies by 40 instead of 20)",
    }
    expl = (f"Heart rate = (number of QRS complexes / strip duration in seconds) × 60 "
            f"= ({n_qrs} / 3) × 60 = {rate} bpm. Equivalently, count in 3 s and "
            f"multiply by 20.")
    stem = (f"The ECG strip shown spans 3.0 seconds and contains {n_qrs} QRS complexes. "
            f"What is the heart rate?")
    return _mk(s, "Body Fluids and Circulation", 11, "Cardiac cycle and ECG",
               "Easy", "application", stem, answers, cwr, expl, subject="Biology")


TEMPLATES: list = [
    _v_circuit,
    _v_wheatstone,
    _v_resistor_colour,
    _v_moving_charge,
    _v_lc_oscillation_phase,
    _v_lens_ray,
    _v_ydse_fringe,
    _v_vt_graph,
    _v_coord_complex,
    _v_titration_curve,
    _v_beam_balance,
    _v_dna_replication_fork,
    _v_pedigree,
    _v_food_chain,
    _v_pulse_rate_graph,
]


# ---------------------------------------------------------------------------
# Selftest
# ---------------------------------------------------------------------------
def _selftest(n_runs: int = 400) -> None:
    from common import RNG as _R
    stems = set()
    for i in range(n_runs):
        t = _R.choice(TEMPLATES)
        q = t()
        assert q["diagram"], f"{t.__name__}: missing diagram"
        assert q["diagram"].endswith(".svg")
        # file exists and is well-formed XML with an <svg> root
        p = DIAGRAM_DIR / q["diagram"]
        assert p.exists(), f"missing diagram file {p}"
        root = ET.fromstring(p.read_text(encoding="utf-8"))
        assert root.tag.endswith("svg")
        assert len(set(q["options"])) == 4
        stems.add((q["subject"], q["question_text"]))
    print(f"diagram_questions selftest: {n_runs} runs OK, "
          f"{len(stems)} unique stems, "
          f"{len(list(DIAGRAM_DIR.glob('*.svg')))} svg files")


if __name__ == "__main__":
    _selftest()
