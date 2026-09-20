"""NEET Biology computed-question templates.

Biology is mostly factual, but a solid subset of NEET bio questions are
COMPUTED: Chargaff's rule, transcription/translation (codon table), Punnett
probabilities, Hardy-Weinberg, DNA base counts. Those live here — answers are
derived, not asserted. The large curated factual bank lives in bio_bank.py /
bio_bank2.py.
"""

from __future__ import annotations

import math
import random
from typing import Callable

from common import Q, RNG, assign_letters, dedupe, remap_cwr, sig

DNA_BASES = "ACGT"
RNA_BASES = "ACGU"

COMPLEMENT_DNA = {"A": "T", "T": "A", "C": "G", "G": "C"}
COMPLEMENT_RNA = {"A": "U", "U": "A", "C": "G", "G": "C"}

# Standard genetic code (subset: all unambiguous sense codons we sample from)
CODON_TABLE: dict[str, str] = {}
for _codons, _aa in [
    (("UUU", "UUC"), "Phenylalanine"), (("UUA", "UUG", "CUU", "CUC", "CUA", "CUG"), "Leucine"),
    (("AUU", "AUC", "AUA"), "Isoleucine"), (("AUG",), "Methionine"),
    (("GUU", "GUC", "GUA", "GUG"), "Valine"), (("UCU", "UCC", "UCA", "UCG", "AGU", "AGC"), "Serine"),
    (("CCU", "CCC", "CCA", "CCG"), "Proline"), (("ACU", "ACC", "ACA", "ACG"), "Threonine"),
    (("GCU", "GCC", "GCA", "GCG"), "Alanine"), (("UAU", "UAC"), "Tyrosine"),
    (("UAA", "UAG", "UGA"), "Stop codon"), (("CAU", "CAC"), "Histidine"),
    (("CAA", "CAG"), "Glutamine"), (("AAU", "AAC"), "Asparagine"), (("AAA", "AAG"), "Lysine"),
    (("GAU", "GAC"), "Aspartic acid"), (("GAA", "GAG"), "Glutamic acid"),
    (("UGU", "UGC"), "Cysteine"), (("UGG",), "Tryptophan"),
    (("CGU", "CGC", "CGA", "CGG", "AGA", "AGG"), "Arginine"),
    (("GGU", "GGC", "GGA", "GGG"), "Glycine"),
]:
    for _c in _codons:
        CODON_TABLE[_c] = _aa

AMINO_ACIDS = sorted({aa for aa in CODON_TABLE.values() if aa != "Stop codon"})


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


def t_chargaff() -> Q:
    """Given %A of dsDNA, find %G: G = (100 - 2A)/2. [NCERT Molecular Basis]"""
    A = RNG.choice([15, 18, 20, 22, 24, 26, 28, 30, 32, 35])
    G = (100 - 2 * A) / 2
    wrongs = dedupe(G, [100.0 - A, float(A), (100 - A) / 2])
    opts = [f"{sig(G, 4)}%"] + [f"{sig(w, 4)}%" for w in wrongs]
    assert len(set(opts)) == 4
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Molecular Basis of Inheritance", "ncert_class": 12, "topic": "Structure of DNA"},
        f"In a double-stranded DNA molecule, adenine constitutes {A}% of the total bases. The percentage of guanine is:",
        opts,
        f"Chargaff's rule: A = T and G = C. A + T = {2 * A}%, so G + C = {100 - 2 * A}%. Since G = C, G = {100 - 2 * A}/2 = {G:g}%. This pairing (A\u2013T with two H-bonds, G\u2261C with three) is the structural basis of the double helix.",
        {
            "B": "computed 100 \u2212 A \u2014 that lumps G + C together instead of splitting the pair",
            "C": "a slip in splitting the G+C pool into its two equal halves",
            "D": "divided the G+C pool incorrectly",
        },
        "Easy", "application", [2015],
    )


def t_dna_base_count() -> Q:
    """dsDNA with N total bases, A given per molecule: G = N - A... careful: total A = total T; given count A -> G = (N - 2A)/2."""
    N = RNG.choice([600, 800, 1000, 1200, 2000])
    A = RNG.choice([N // 5, 3 * N // 10, N // 3])
    if 2 * A >= N:
        A = N // 5
    G = (N - 2 * A) / 2
    wrongs = dedupe(G, [float(N - A), float(A), (N - A) / 2])
    opts = [f"{G:g}"] + [f"{w:g}" for w in wrongs]
    assert len(set(opts)) == 4, opts
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Molecular Basis of Inheritance", "ncert_class": 12, "topic": "Structure of DNA"},
        f"A double-stranded DNA molecule contains {N} nucleotides in total, of which {A} are adenine. The number of guanine nucleotides is:",
        opts,
        f"A pairs only with T, so T = {A} as well. A + T = {2 * A}, leaving {N} \u2212 {2 * A} = {N - 2 * A} nucleotides shared equally by G and C. G = {N - 2 * A}/2 = {G:g}.",
        {
            "B": "subtracted only A (forgot T equals A in double-stranded DNA)",
            "C": "a slip in splitting the leftover G+C pool between G and C",
            "D": "halved the wrong pool",
        },
        "Medium", "application", [2017],
    )


def t_transcription() -> Q:
    """Coding strand 5'-NNN-3' -> mRNA identical with U for T. [NCERT]"""
    for _try in range(60):
        coding = "".join(RNG.choice(DNA_BASES) for _ in range(6))
        mrna = coding.replace("T", "U")
        template_rna = "".join(COMPLEMENT_DNA[b] for b in coding).replace("T", "U")
        opts = [mrna, template_rna, coding, mrna[::-1]]
        if len(set(opts)) == 4:
            break
    assert len(set(opts)) == 4, opts
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Molecular Basis of Inheritance", "ncert_class": 12, "topic": "Transcription"},
        f"The coding (sense) strand of a DNA segment is 5'-{coding}-3'. The mRNA transcribed from it is:",
        opts,
        f"The mRNA is complementary to the TEMPLATE strand \u2014 which makes it IDENTICAL in sequence to the coding strand, with T replaced by U: 5'-{mrna}-3'. RNA contains uracil, never thymine.",
        {
            "B": "wrote the template strand's complement \u2014 that RNA never leaves the nucleus; mRNA matches the CODING strand (U for T)",
            "C": "kept thymine \u2014 RNA transcription substitutes uracil for thymine",
            "D": "reversed the polarity \u2014 mRNA is synthesised and read 5' \u2192 3'",
        },
        "Medium", "application", [2018],
    )


def t_codon_translate() -> Q:
    """mRNA codon -> amino acid via the standard code. [NCERT]"""
    sense = [c for c, aa in CODON_TABLE.items() if aa != "Stop codon"]
    codon = RNG.choice(sense)
    correct = CODON_TABLE[codon]
    wrongs = RNG.sample([aa for aa in AMINO_ACIDS if aa != correct], 3)
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Molecular Basis of Inheritance", "ncert_class": 12, "topic": "Genetic Code and Translation"},
        f"During translation, the mRNA codon {codon} specifies which amino acid?",
        [correct] + wrongs,
        f"Reading the standard genetic code, {codon} codes for {correct}. The code is unambiguous (one codon, one meaning) though degenerate (most amino acids have several codons). AUG also doubles as the start codon; UAA/UAG/UGA are stops.",
        {
            "B": "a codon-table slip \u2014 check the first base family (U, C, A, G boxes) and the second base",
            "C": "confused two codon boxes with similar second letters",
            "D": "a near-miss codon family (one base apart) was read",
        },
        "Easy", "recall", [2016],
    )


def t_anticodon() -> Q:
    """mRNA codon -> tRNA anticodon (3'->5' pairing, written 3'-...-5' opposite)."""
    # Palindromic codons (e.g. CGC) make the anticodon, its reverse, and the
    # DNA-complement slip identical — resample until all four options differ.
    for _try in range(60):
        codon = "".join(RNG.choice(RNA_BASES) for _ in range(3))
        anti = "".join(COMPLEMENT_RNA[b] for b in codon)
        dna_like = "".join(COMPLEMENT_DNA[b] for b in codon.replace("U", "T"))  # thymine slip
        opts = [anti, codon, anti[::-1], dna_like]
        if len(set(opts)) == 4:
            break
    assert len(set(opts)) == 4, opts
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Molecular Basis of Inheritance", "ncert_class": 12, "topic": "Translation: tRNA"},
        f"A tRNA must read the mRNA codon {codon}. Its anticodon (antiparallel pairing) is:",
        opts,
        f"The anticodon pairs ANTIPARALLEL with the codon: A\u2013U, G\u2013C. For codon {codon}, the anticodon is {anti} (its 3' end pairs with the codon's 5' base). The anticodon is RNA, so uracil \u2014 never thymine.",
        {
            "B": "copied the codon itself \u2014 identical sequences cannot base-pair",
            "C": "reversed the pairing order (wrong polarity)",
            "D": "used DNA complementarity (thymine instead of uracil)",
        },
        "Medium", "application", None,
    )


def t_monohybrid() -> Q:
    """Monohybrid ratios: F2 phenotype 3:1, genotype 1:2:1, testcross 1:1."""
    mode = RNG.choice(["f2_pheno", "f2_genotype", "testcross_pheno"])
    meta = {"id": "", "subject": "Biology", "chapter": "Principles of Inheritance and Variation", "ncert_class": 12, "topic": "Mendel's Laws"}
    if mode == "f2_pheno":
        return _mk(meta,
            "In Mendel's monohybrid cross (Tt \u00d7 Tt), the phenotypic ratio in the F\u2082 generation is:",
            ["3 tall : 1 dwarf", "1 : 2 : 1", "1 tall : 1 dwarf", "9 : 3 : 3 : 1"],
            "Tt \u00d7 Tt gives TT : Tt : tT : tt = 1 : 2 : 1 genotypically. Since T (tall) is dominant over both TT and Tt, the phenotypes collapse to 3 tall : 1 dwarf. The 1 : 2 : 1 is the GENOTYPIC ratio \u2014 the 9 : 3 : 3 : 1 belongs to dihybrid crosses.",
            {
                "B": "quoted the genotypic ratio instead of the phenotypic one",
                "C": "gave the testcross ratio (Tt \u00d7 tt)",
                "D": "used the dihybrid F\u2082 ratio \u2014 that needs two gene pairs",
            },
            "Easy", "recall", [2014])
    if mode == "f2_genotype":
        return _mk(meta,
            "In a monohybrid cross of two heterozygotes (Rr \u00d7 Rr), the GENOTYPIC ratio in the F\u2082 is:",
            ["1 RR : 2 Rr : 1 rr", "3 round : 1 wrinkled", "1 : 1", "2 RR : 2 rr"],
            "Punnett: RR (1/4), Rr (2/4), rr (1/4) \u2192 1 : 2 : 1. The phenotypes merge (RR and Rr both round-seeded) to give 3 : 1 outwardly, but the underlying genotypes remain three classes.",
            {
                "B": "the phenotypic ratio \u2014 the question asks for genotypes",
                "C": "a testcross ratio",
                "D": "impossible segregation \u2014 heterozygotes must appear",
            },
            "Easy", "recall", None)
    return _mk(meta,
        "A tall heterozygous pea plant (Tt) is crossed with a dwarf plant (tt). The expected phenotypic ratio of the offspring is:",
        ["1 tall : 1 dwarf", "3 tall : 1 dwarf", "all tall", "all dwarf"],
        "Tt \u00d7 tt (a testcross): gametes T and t meet t and t, giving Tt (tall) and tt (dwarf) in equal numbers \u2014 1 : 1. A 1 : 1 ratio from a dominant phenotype \u00d7 recessive phenotype cross is Mendel's evidence that the tall parent was heterozygous.",
        {
            "B": "used the F\u2082 self-pollination ratio instead of a testcross",
            "C": "ignored the homozygous recessive parent's contribution",
            "D": "assumed the dwarf allele masked the tall allele \u2014 dominance runs the other way",
        },
        "Easy", "application", [2015],
    )


def t_dihybrid_probability() -> Q:
    """AaBb x AaBb: probability of a specified phenotype class. [NEET recurring]"""
    targets = [
        ("both dominant traits (A_B_)", 9 / 16, "9/16"),
        ("both recessive traits (aabb)", 1 / 16, "1/16"),
        ("A dominant, b recessive (A_bb)", 3 / 16, "3/16"),
        ("aaB_", 3 / 16, "3/16"),
        ("recessive for exactly one gene and dominant for the other", 6 / 16, "6/16"),
    ]
    label, frac, frac_str = RNG.choice(targets)
    wrong_fr = sorted({9, 1, 3, 6, 4} - {round(frac * 16)})
    opts = [frac_str, f"{wrong_fr[0]}/16", f"{wrong_fr[1]}/16", f"{wrong_fr[2]}/16"]
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Principles of Inheritance and Variation", "ncert_class": 12, "topic": "Dihybrid Cross"},
        f"In a dihybrid cross AaBb \u00d7 AaBb (genes assorting independently), the probability of offspring that are {label} is:",
        opts,
        f"Each gene segregates 3/4 dominant : 1/4 recessive. Independent assortment multiplies: {label} requires the product {frac_str} of the 16 Punnett combinations. Mendel's 9 : 3 : 3 : 1 sums exactly these four classes.",
        {
            "B": "a miscount of the 16 Punnett boxes \u2014 count dominant/recessive per gene, then multiply",
            "C": "added probabilities instead of multiplying independent events",
            "D": "confused a genotype class with the phenotype class",
        },
        "Medium", "application", [2019],
    )


def t_hardy_weinberg() -> Q:
    """Given q^2, find 2pq (heterozygotes). [NEET recurring evolution]"""
    q2_pct = RNG.choice([4, 9, 16, 25, 36])
    q = math.sqrt(q2_pct / 100)
    p = 1 - q
    het = 2 * p * q
    het_pct = het * 100
    wrongs = dedupe(het_pct, [p * 100, float(q2_pct), q * 100])
    opts = [f"{sig(het_pct, 4)}%"] + [f"{sig(w, 4)}%" for w in wrongs]
    assert len(set(opts)) == 4
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Evolution", "ncert_class": 12, "topic": "Hardy-Weinberg Principle"},
        f"In a population at Hardy\u2013Weinberg equilibrium, {q2_pct}% of individuals show a recessive trait (q\u00b2 = {q2_pct / 100:g}). The frequency of heterozygous carriers is:",
        opts,
        f"q = \u221a({q2_pct / 100:g}) = {sig(q, 3)}. p = 1 \u2212 q = {sig(p, 3)}. Heterozygotes 2pq = 2 \u00d7 {sig(p, 3)} \u00d7 {sig(q, 3)} = {sig(het, 3)} \u2248 {sig(het_pct, 3)}% of the population \u2014 usually far MORE carriers than affected homozygotes, which is why recessive alleles hide in populations.",
        {
            "B": "reported the dominant homozygote frequency p\u00b2 territory",
            "C": "echoed the given q\u00b2 \u2014 that is the affected homozygote frequency",
            "D": "halved the heterozygote frequency",
        },
        "Hard", "application", [2021],
    )


def t_blood_group_cross() -> Q:
    """ABO genetics: P(child phenotype) for given parents. [NEET recurring]"""
    cases = [
        ("IAi (A) \u00d7 IBi (B)", {"A": 25, "B": 25, "AB": 25, "O": 25}),
        ("IAIA (A) \u00d7 IBi (B)", {"A": 50, "B": 50, "AB": 0, "O": 0}),
        ("IAi (A) \u00d7 ii (O)", {"A": 50, "B": 0, "AB": 0, "O": 50}),
        ("IAIB (AB) \u00d7 ii (O)", {"A": 50, "B": 50, "AB": 0, "O": 0}),
        ("ii (O) \u00d7 ii (O)", {"A": 0, "B": 0, "AB": 0, "O": 100}),
    ]
    parents, probs = RNG.choice(cases)
    phenos = ["A", "B", "AB", "O"]
    ask = RNG.choice([ph for ph in phenos if probs[ph] > 0] or ["O"])
    correct = f"{probs[ask]}%"
    wrongs = sorted({0, 25, 50, 100} - {probs[ask]})[:3]
    opts = [correct] + [f"{w}%" for w in wrongs]
    assert len(set(opts)) == 4
    return _mk(
        {"id": "", "subject": "Biology", "chapter": "Principles of Inheritance and Variation", "ncert_class": 12, "topic": "Genetics of ABO Blood Groups"},
        f"A couple has blood groups {parents}. The probability that their child has blood group {ask} is:",
        opts,
        f"ABO shows codominance (IA = IB) with i recessive. Cross {parents}: run the Punnett square over the alleles each parent contributes. P(child = {ask}) = {probs[ask]}%. Multiple alleles + codominance is why the ABO system breaks simple dominance intuition.",
        {
            "B": "a Punnett slip \u2014 list each parent's alleles explicitly before combining",
            "C": "misapplied dominance \u2014 A and B are codominant with each other",
            "D": "ignored the recessive i allele's contribution",
        },
        "Medium", "application", [2020],
    )


def t_sequential_meiosis() -> Q:
    """DNA content / chromosome number through meiosis. [NEET recurring cell cycle]"""
    mode = RNG.choice(["after_meiosis_I_DNA", "after_meiosis_II_chrom", "pachytene_event"])
    meta = {"id": "", "subject": "Biology", "chapter": "Cell Cycle and Cell Division", "ncert_class": 11, "topic": "Meiosis"}
    if mode == "after_meiosis_I_DNA":
        return _mk(meta,
            "A meiocyte has 2n = 4 chromosomes and 4C DNA after the S phase. At the end of meiosis I, each daughter cell has:",
            ["2 chromosomes and 2C DNA", "4 chromosomes and 4C DNA", "2 chromosomes and 1C DNA", "4 chromosomes and 2C DNA"],
            "Meiosis I is REDUCTIONAL: homologous chromosomes separate, so the chromosome number halves (4 \u2192 2) and ploidy drops from diploid to haploid. However, each chromosome still consists of two sister chromatids, so the DNA content only halves (4C \u2192 2C), not to 1C. Chromatids separate later, in meiosis II.",
            {
                "B": "kept the pre-meiotic state \u2014 homologous chromosomes did separate",
                "C": "halved the DNA twice \u2014 chromatid separation happens in meiosis II, not meiosis I",
                "D": "reduced the DNA content but forgot the chromosome number also halved",
            },
            "Medium", "application", [2018])
    if mode == "after_meiosis_II_chrom":
        return _mk(meta,
            "A cell with 2n = 8 completes meiosis II. Each resulting cell contains:",
            ["4 chromosomes, 2C DNA", "8 chromosomes, 4C DNA", "4 chromosomes, 4C DNA", "8 chromosomes, 2C DNA"],
            "Meiosis II is equational (mitosis-like): sister chromatids separate. n = 4 after meiosis I; after meiosis II each cell keeps 4 chromosomes with single chromatids \u2014 2C DNA (where C is one chromatid's worth per haploid set).",
            {
                "B": "the starting meiocyte state \u2014 two divisions have occurred",
                "C": "chromosome number right but chromatids not separated",
                "D": "kept the diploid chromosome number",
            },
            "Medium", "application", None)
    return _mk(meta,
        "Crossing over occurs at which stage of meiosis I?",
        ["Pachytene (of prophase I)", "Zygotene", "Leptotene", "Diakinesis"],
        "Prophase I sub-stages: leptotene (chromosomes condense), zygotene (synapsis, synaptonemal complex forms), PACHYTENE (recombination nodules appear \u2014 crossing over happens here), diplotene (chiasmata visible, nuclear envelope breakdown begins), diakinesis (terminalisation).",
        {
            "B": "zygotene is pairing/synapsis, not recombination",
            "C": "leptotene only condenses the chromosomes",
            "D": "diakinesis terminalises chiasmata \u2014 the exchange already happened",
        },
        "Easy", "recall", [2015],
    )


TEMPLATES: list[Callable[[], Q]] = [
    t_chargaff, t_dna_base_count, t_transcription, t_codon_translate, t_anticodon,
    t_monohybrid, t_dihybrid_probability, t_hardy_weinberg, t_blood_group_cross,
    t_sequential_meiosis,
]


def generate(count: int, start_id: int = 9500) -> list[Q]:
    out: list[Q] = []
    per = [count // len(TEMPLATES)] * len(TEMPLATES)
    for i in range(count % len(TEMPLATES)):
        per[i] += 1
    next_id = start_id
    guard = 0
    while any(p > 0 for p in per):
        idx = RNG.randrange(len(TEMPLATES))
        if per[idx] <= 0:
            continue
        per[idx] -= 1
        q = TEMPLATES[idx]()
        q["id"] = f"NEET-{next_id}"
        next_id += 1
        out.append(q)
        guard += 1
        if guard > count * 3:
            break
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
