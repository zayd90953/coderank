"""NEET Biology computed-question templates — volume extension (P0).

Same contract as bio_templates.py: answers are DERIVED from parameters
(protein length from codon count, Mendelian ratios, Hardy-Weinberg carrier
frequency, growth equations, species-area relation, semiconservative
replication fractions, trophic transfer, bacterial growth). Distractors are
named errors, deduped via common.dedupe. Existing families (Chargaff,
transcription, Punnett, Hardy-Weinberg p-given, meiosis staging) live in
bio_templates.py and are NOT duplicated here.

Run selftest:  python demo_set_qns/generators/bio_templates2.py
"""

from __future__ import annotations

from typing import Callable

from common import Q, RNG, assign_letters, dedupe, remap_cwr, sig


def _mk(subject_meta, question_text, answers, explanation, cwr, difficulty, bloom, pyq) -> Q:
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


def _bio(chapter: str, ncert_class: int, topic: str) -> dict:
    return {"id": "", "subject": "Biology", "chapter": chapter,
            "ncert_class": ncert_class, "topic": topic}


# ---------------------------------------------------------------------------
# 1. Protein length from mRNA length
# ---------------------------------------------------------------------------
def t_protein_length() -> Q:
    """mRNA with N bases (incl. stop codon) -> (N-3)/3 amino acids."""
    k = RNG.choice([40, 60, 80, 100, 120, 150, 200, 250, 300])
    N = 3 * k + 3                      # k sense codons + 1 stop codon
    aa = (N - 3) // 3
    wrongs = dedupe(float(aa), [N / 3, (N - 3) / 6, N / 6])
    opts = [str(aa)] + [sig(w, 4) for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Molecular Basis of Inheritance", 12, "Translation"),
        f"A bacterial mRNA is {N} nucleotides long and includes a stop codon. "
        f"How many amino acids does the polypeptide translated from it contain?",
        opts,
        f"Translation reads the mRNA in triplets, but the stop codon codes for no "
        f"amino acid — it only terminates translation. Sense codons = {N} − 3 = "
        f"{N - 3}, so amino acids = {N - 3}/3 = {aa}. Forgetting to subtract the "
        f"stop codon is the classic error here.",
        {
            "B": f"divided {N}/3 without removing the stop codon from the reading frame",
            "C": "divided twice by 3 — confused nucleotides with codons twice over",
            "D": "applied the stop-codon subtraction but then halved the codon count",
        },
        "Easy", "application", [2020],
    )


# ---------------------------------------------------------------------------
# 2. Mendelian ratio counts (F2 / testcross progeny counts)
# ---------------------------------------------------------------------------
def t_mendelian_ratio_counts() -> Q:
    """Typical Mendelian ratios with T total progeny -> expected count of a class."""
    fam = RNG.choice(["mono_f2", "di_f2", "tri_f2_recessive"])
    if fam == "mono_f2":
        T = RNG.choice([200, 400, 600, 800, 1000])
        cls, frac, desc = RNG.choice([
            ("dominant phenotype for the single trait", 3 / 4, "3/4"),
            ("recessive phenotype for the single trait", 1 / 4, "1/4"),
        ])
        count = frac * T
        wrongs = dedupe(count, [T / 2, T * frac / 2, T / 16])
        expl_ratio = "monohybrid F2 shows a 3 : 1 phenotype ratio"
    elif fam == "di_f2":
        T = RNG.choice([160, 320, 480, 640, 800, 1600])
        cls, frac, desc = RNG.choice([
            ("both dominant characters", 9 / 16, "9/16"),
            ("both recessive characters", 1 / 16, "1/16"),
            ("dominant A with recessive b", 3 / 16, "3/16"),
            ("recessive a with dominant B", 3 / 16, "3/16"),
        ])
        count = frac * T
        wrongs = dedupe(count, [T / 2, T / 4, 9 * T / 16 if frac != 9 / 16 else 3 * T / 16])
        expl_ratio = "dihybrid F2 shows the 9 : 3 : 3 : 1 phenotype ratio"
    else:
        T = RNG.choice([640, 1280, 2560, 5120])
        cls, frac, desc = ("all three characters recessive", 1 / 64, "1/64")
        count = frac * T
        wrongs = dedupe(count, [T / 16, T / 27, T / 8])
        expl_ratio = ("a trihybrid F2 shows the 27 : 9 : 9 : 9 : 3 : 3 : 3 : 1 ratio; "
                      "all-recessive is the single 1/64 class")
    opts = [str(int(count))] + [sig(w, 6) for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Principles of Inheritance and Variation", 12, "Mendelian inheritance"),
        f"A cross yields {T} F2 offspring in the typical Mendelian pattern. How many "
        f"are expected to show the phenotype: {cls}?",
        opts,
        f"{expl_ratio.capitalize()}. The asked class carries {desc} of the progeny, "
        f"so the expected count is {desc} × {T} = {int(count)}. Independence of "
        f"characters is what produces these exact fractional expectations.",
        {
            "B": "used a 1 : 1 split instead of the phenotype ratio for this cross",
            "C": "used 1/4 (a single-gene probability) regardless of the cross type",
            "D": "applied a ratio from a different cross (wrong generation/class)",
        },
        "Medium", "application", [2018],
    )


# ---------------------------------------------------------------------------
# 3. Carrier frequency from disease incidence (q^2 given)
# ---------------------------------------------------------------------------
def t_carrier_frequency() -> Q:
    """Recessive disorder incidence q² = 1/D -> carriers 2pq ≈ 2/D."""
    D = RNG.choice([100, 400, 900, 2500, 3600, 10000])
    q = 1.0 / (D ** 0.5)
    p = 1.0 - q
    carriers = 2 * p * q
    carriers_pct = carriers * 100
    wrongs = dedupe(carriers_pct, [100.0 / D, 200.0 / D, q * 100])
    opts = [f"{sig(carriers_pct, 3)}%"] + [f"{sig(w, 3)}%" for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Evolution", 12, "Hardy-Weinberg principle"),
        f"In a large randomly mating population, a recessive genetic disorder affects "
        f"1 in {D} newborns. Approximately what percentage of the population are "
        f"unaffected carriers (heterozygotes)?",
        opts,
        f"Affected individuals are q², so q² = 1/{D} → q = 1/{int(D ** 0.5)} = "
        f"{sig(q, 4)}. Then p = 1 − q = {sig(p, 4)}. Carrier frequency = 2pq = "
        f"2 × {sig(p, 4)} × {sig(q, 4)} = {sig(carriers, 4)} ≈ {sig(carriers_pct, 3)}%. "
        f"Carriers are far commoner than affected individuals — the hallmark of a "
        f"rare recessive allele.",
        {
            "B": f"reported the incidence q² itself (1/{D}) instead of the carrier frequency",
            "C": "used 2q instead of 2pq (dropped the p factor and mis-scaled)",
            "D": "reported q (the allele frequency) as if it were the genotype frequency",
        },
        "Hard", "analysis", [2021],
    )


# ---------------------------------------------------------------------------
# 4. Exponential growth dN/dt = rN
# ---------------------------------------------------------------------------
def t_exponential_growth() -> Q:
    """dN/dt = rN for a population in the exponential phase."""
    N = RNG.choice([2000, 2500, 4000, 5000, 8000, 10000])
    r = RNG.choice([0.02, 0.05, 0.1, 0.15, 0.2, 0.25])
    dN = r * N
    wrongs = dedupe(dN, [r * 100, N + r, dN / 2])
    opts = [sig(dN, 5)] + [sig(w, 5) for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Organisms and Populations", 12, "Population growth"),
        f"A population of {N} individuals is growing exponentially with an intrinsic "
        f"rate of natural increase r = {r} per individual per year. What is dN/dt?",
        opts,
        f"Exponential growth: dN/dt = rN = {r} × {N} = {sig(dN, 5)} individuals per "
        f"year. The per-capita rate r multiplies the whole population — no carrying "
        f"capacity term appears in the exponential model.",
        {
            "B": "attached r to a fixed 100 rather than to the population size N",
            "C": "added r to N instead of multiplying (wrong operation)",
            "D": "halved the product — an arithmetic slip in applying dN/dt = rN",
        },
        "Easy", "application", None,
    )


# ---------------------------------------------------------------------------
# 5. Logistic growth dN/dt = rN(K-N)/K
# ---------------------------------------------------------------------------
def t_logistic_growth() -> Q:
    """Logistic growth with N = K/4 drawn: dN/dt = rN(K-N)/K."""
    K = RNG.choice([400, 600, 800, 1000, 2000])
    r = RNG.choice([0.1, 0.2, 0.3, 0.4])
    N = K // 4
    dN = r * N * (K - N) / K
    wrongs = dedupe(dN, [r * N, r * K, dN * 2])
    opts = [sig(dN, 5)] + [sig(w, 5) for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Organisms and Populations", 12, "Population growth"),
        f"A population of {N} individuals grows logistically with r = {r} and "
        f"carrying capacity K = {K}. What is dN/dt at this population size?",
        opts,
        f"Logistic growth: dN/dt = rN(K − N)/K = {r} × {N} × ({K} − {N})/{K} = "
        f"{r} × {N} × {sig((K - N) / K, 3)} = {sig(dN, 5)} individuals. The "
        f"(K − N)/K factor is the fraction of the carrying capacity still unused — "
        f"it slows growth as N approaches K, unlike the exponential model.",
        {
            "B": "dropped the (K − N)/K term — that is the exponential model, not logistic",
            "C": "applied r to K instead of to N",
            "D": "arithmetic slip in evaluating rN(K − N)/K",
        },
        "Hard", "analysis", None,
    )


# ---------------------------------------------------------------------------
# 6. Species-area relation S = C A^z
# ---------------------------------------------------------------------------
def t_species_area() -> Q:
    """S2 = S1 (A2/A1)^z with clean powers; z from the NCERT 0.1-0.7 range."""
    S1 = RNG.choice([20, 40, 50, 80, 100, 200])
    ratio, root = RNG.choice([(4, 2), (9, 3), (16, 4), (100, 10)])
    z = RNG.choice([0.5, 0.25])
    factor = ratio ** z
    S2 = S1 * factor
    wrongs = dedupe(S2, [S1 * ratio, S1 + ratio, S2 / 2])
    opts = [sig(S2, 5)] + [sig(w, 5) for w in wrongs]
    assert len(set(opts)) == 4, opts
    ztxt = "0.5" if z == 0.5 else "0.25"
    expl_factor = (f"({ratio})^{ztxt} = {sig(factor, 4)}"
                   if z == 0.5 else
                   f"({ratio})^0.25 = √(√{ratio}) = {sig(factor, 4)}")
    return _mk(
        _bio("Biodiversity and Conservation", 12, "Species-area relationships"),
        f"On a log-log species-area plot following S = C·A^z, a habitat with area "
        f"A₁ supports {S1} species. If a second habitat is {ratio}× larger and the "
        f"slope value is z = {ztxt}, how many species does it support?",
        opts,
        f"S₂ = S₁ · (A₂/A₁)^z = {S1} × {expl_factor} = {sig(S2, 5)} species. "
        f"Because z < 1, species count rises sub-linearly with area — a {ratio}× "
        f"area gives far fewer than {ratio}× the species. Real z values range "
        f"roughly 0.1 to 0.7.",
        {
            "B": "extrapolated linearly (S scales with area) — valid only for z = 1",
            "C": "added the area ratio instead of raising it to the power z",
            "D": "arithmetic slip in evaluating the power term",
        },
        "Hard", "analysis", None,
    )


# ---------------------------------------------------------------------------
# 7. Semiconservative replication fractions
# ---------------------------------------------------------------------------
def t_semiconservative() -> Q:
    """After n generations in 14N medium, hybrid fraction = 100/2^(n-1)%."""
    n = RNG.choice([2, 3, 4, 5, 6])
    hybrid = 100.0 / (2 ** (n - 1))
    wrongs = dedupe(hybrid, [100.0 / (2 ** n), 50.0 / (2 ** (n - 1)), 100.0 / (2 ** (n + 1))])
    opts = [f"{sig(hybrid, 4)}%"] + [f"{sig(w, 4)}%" for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Molecular Basis of Inheritance", 12, "DNA replication"),
        f"Cells growing in ¹⁵N medium are shifted to ¹⁴N medium and allowed to "
        f"divide for {n} generations (semiconservative replication). What percentage "
        f"of the DNA is hybrid (¹⁵N-¹⁴N) after {n} generations?",
        opts,
        f"Semiconservative replication: every generation doubles the molecule count "
        f"while the two original ¹⁵N-¹⁵N strands persist in exactly 2 hybrid "
        f"molecules. After {n} generations there are 2^{n} = {2 ** n} molecules, so "
        f"hybrid fraction = 2/2^{n} = 1/2^{n - 1} = {sig(hybrid, 4)}%. All the rest "
        f"are light ¹⁴N-¹⁴N.",
        {
            "B": f"halved one extra time (used 2^{n} molecules in the denominator)",
            "C": "began halving from 50% instead of 100% (generation miscount)",
            "D": "shifted the exponent the wrong way in the doubling series",
        },
        "Medium", "analysis", [2016],
    )


# ---------------------------------------------------------------------------
# 8. Trophic energy transfer (10% law, text form)
# ---------------------------------------------------------------------------
def t_energy_transfer() -> Q:
    """Producers fix P kJ; secondary consumers receive P × 0.01."""
    P = RNG.choice([20000, 40000, 50000, 80000, 100000, 200000])
    sec = P * 0.01
    wrongs = dedupe(sec, [P * 0.1, P * 0.001, sec * 5])
    opts = [f"{sig(sec, 6)} kJ"] + [f"{sig(w, 6)} kJ" for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Ecosystem", 12, "Energy flow in ecosystems"),
        f"Producers in an ecosystem fix {P} kJ of energy. Assuming the 10 percent "
        f"law of energy transfer, how much energy reaches the secondary consumers "
        f"(third trophic level)?",
        opts,
        f"Each transfer passes on 10%: producers {P} → primary consumers "
        f"{sig(P * 0.1, 6)} → secondary consumers {sig(sec, 6)} kJ. Two transfers, "
        f"each ×1/10, compound to ×1/100 overall. The rest is lost to respiration "
        f"and unavailable to the next level.",
        {
            "B": "applied the 10% law only once — that is the primary-consumer level",
            "C": "applied the 10% law three times (counted one extra level)",
            "D": "misapplied the compounding of two successive transfers",
        },
        "Easy", "application", [2019],
    )


# ---------------------------------------------------------------------------
# 9. Bacterial growth N = N0 × 2^k
# ---------------------------------------------------------------------------
def t_bacterial_growth() -> Q:
    """N0 bacteria after k generations: N = N0 × 2^k."""
    N0 = RNG.choice([1000, 10000, 100000])
    k = RNG.choice([3, 4, 5, 6, 8])
    N = N0 * (2 ** k)
    wrongs = dedupe(float(N), [N0 * k, float(N0 * 2 * k), N / 2])
    opts = [sig(N, 8)] + [sig(w, 8) for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        _bio("Microbes in Human Welfare", 12, "Microbial growth"),
        f"A bacterial culture starts with {N0} cells and doubles every generation. "
        f"After {k} generations, the total number of cells is:",
        opts,
        f"Binary fission doubles the population each generation: N = N₀ × 2^k = "
        f"{N0} × 2^{k} = {N0} × {2 ** k} = {sig(N, 8)} cells. Multiplying by k "
        f"instead of raising 2 to the k-th power is the standard slip.",
        {
            "B": "multiplied by the generation count instead of doubling k times",
            "C": "confused doubling (×2) with linear growth (×2k)",
            "D": "counted one doubling fewer than the generations given",
        },
        "Medium", "application", None,
    )


TEMPLATES: list[Callable[[], Q]] = [
    t_protein_length,
    t_mendelian_ratio_counts,
    t_carrier_frequency,
    t_exponential_growth,
    t_logistic_growth,
    t_species_area,
    t_semiconservative,
    t_energy_transfer,
    t_bacterial_growth,
]


# ---------------------------------------------------------------------------
# Selftest
# ---------------------------------------------------------------------------
def _selftest(n_runs: int = 600) -> None:
    from common import RNG as _R
    stems = set()
    for _ in range(n_runs):
        t = _R.choice(TEMPLATES)
        q = t()
        assert len(set(q["options"])) == 4, t.__name__
        assert q["diagram"] is None
        stems.add(q["question_text"])
    print(f"bio_templates2 selftest: {n_runs} runs OK, {len(stems)} unique stems")


if __name__ == "__main__":
    _selftest()
