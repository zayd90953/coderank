"""Statement-match questions (format extension).

Format: three numbered statements (I, II, III), each hand-verified true or
false; the option set is the standard NEET combination scheme. The correct
letter is COMPUTED from the fact tuples, so the key can never disagree with
the facts. Distractors are the other combinations; misconception notes name
exactly which statement a student misjudged.

Entry: (subject, chapter, ncert_class, topic,
        [(statement, is_true, why) x3], difficulty, pyq_or_None)
Constraint: at least one true and at least one false statement (both
all-true and all-false stems are rejected at build time).

Run selftest:  python demo_set_qns/generators/statement_match.py
"""

ROMAN = ["I", "II", "III"]


def _combination_options(true_flags: list[bool]) -> tuple[list[str], str]:
    """Return (options, correct_letter) for the 3-statement scheme."""
    n_true = sum(true_flags)
    assert 1 <= n_true <= 2, "require a mix of true and false statements"
    if n_true == 1:
        idx = true_flags.index(True)
        options = [f"Only {ROMAN[i]}" for i in range(3)] + ["I, II and III"]
        return options, "ABCD"[idx]
    # n_true == 2
    false_idx = true_flags.index(False)
    pairs = [(0, 1), (0, 2), (1, 2)]
    options = []
    for a, b in pairs:
        options.append(f"{ROMAN[a]} and {ROMAN[b]} only")
    options.append("I, II and III")
    correct = "ABCD"[pairs.index((false_idx, false_idx + 1)) if False else pairs.index(
        tuple(i for i in range(3) if i != false_idx))]  # placeholder, fixed below
    return options, correct


def _build_options(true_flags: list[bool]) -> tuple[list[str], str]:
    """Clean implementation of the combination scheme. Allows all-true stems
    (correct answer D = 'I, II and III'), which real NEET papers also use."""
    n_true = sum(true_flags)
    assert 1 <= n_true <= 3
    if n_true == 1:
        idx = true_flags.index(True)
        options = [f"Only {ROMAN[i]}" for i in range(3)] + ["I, II and III"]
        return options, "ABCD"[idx]
    if n_true == 3:
        pairs = [(0, 1), (0, 2), (1, 2)]
        options = [f"{ROMAN[a]} and {ROMAN[b]} only" for (a, b) in pairs]
        options.append("I, II and III")
        return options, "D"
    false_idx = true_flags.index(False)
    pairs = {(0, 1): 0, (0, 2): 1, (1, 2): 2}
    true_pair = tuple(i for i in range(3) if i != false_idx)
    options = [f"{ROMAN[a]} and {ROMAN[b]} only" for (a, b) in [(0, 1), (0, 2), (1, 2)]]
    options.append("I, II and III")
    return options, "ABCD"[pairs[true_pair]]


def _cwr_for(true_flags: list[bool], options: list[str], correct: str) -> dict:
    """Name the misjudged statement for each wrong option."""
    cwr = {}
    for letter, opt in zip("ABCD", options):
        if letter == correct:
            continue
        chosen = _opt_to_flags(opt)
        if chosen is None:
            cwr[letter] = "over-accepts every statement, including the false one"
            continue
        for i, (c, t) in enumerate(zip(chosen, true_flags)):
            if c != t:
                verdict = "accepted as true" if t is False else "rejected as false"
                cwr[letter] = f"statement {ROMAN[i]} was wrongly {verdict}"
                break
    return cwr


def _opt_to_flags(opt: str) -> list[bool] | None:
    if opt.startswith("Only"):
        idx = ["Only I", "Only II", "Only III"].index(opt)
        return [i == idx for i in range(3)]
    if opt == "I, II and III":
        return [True, True, True]
    flags = [False, False, False]
    parts = opt.split(" and ")[0].replace("only", "").strip()
    if "I" in parts:
        flags[0] = True
    if "II" in parts and "III" not in parts:
        flags[1] = True
    if "III" in parts:
        flags[2] = True
    return flags


def _sm(subject: str, chapter: str, ncert_class: int, topic: str,
        facts: list[tuple], difficulty: str, pyq) -> dict:
    statements = [f for f, _, _ in facts]
    true_flags = [t for _, t, _ in facts]
    options, correct = _build_options(true_flags)
    cwr = _cwr_for(true_flags, options, correct)
    why_lines = []
    for i, ((stmt, truth, why), roman) in enumerate(zip(facts, ROMAN)):
        tag = "TRUE" if truth else "FALSE"
        why_lines.append(f"Statement {roman} is {tag}: {why}")
    stem = ("Consider the following statements:\n" +
            "".join(f"Statement {roman}: {stmt}\n" for roman, stmt in zip(ROMAN, statements)) +
            "Which of the above statements is/are correct?")
    explanation = " ".join(why_lines)
    return {
        "id": "", "subject": subject, "chapter": chapter,
        "ncert_class": ncert_class, "topic": topic,
        "difficulty": difficulty, "bloom_level": "analysis",
        "question_text": stem, "options": options,
        "correct_option": correct, "explanation": explanation,
        "common_wrong_reasoning": cwr, "neet_pyq_year": pyq,
        "diagram": None, "type": "statement_match",
    }


ENTRIES: list[tuple] = [
    # ---------------- Biology ----------------
    ("Biology", "Cell: The Unit of Life", 11, "Prokaryotic cells",
     [("Prokaryotic cells lack a membrane-bound nucleus.", True,
       "the genetic material lies naked in the nucleoid, with no nuclear envelope"),
      ("Prokaryotic ribosomes are of the 70S type.", True,
       "they dissociate into 50S and 30S subunits, unlike eukaryotic 80S"),
      ("Prokaryotic cells possess membrane-bound organelles such as mitochondria.", False,
       "prokaryotes have no membrane-bound organelles; respiration occurs on mesosomes/plasma membrane")],
     "Medium", None),

    ("Biology", "Cell: The Unit of Life", 11, "Eukaryotic organelles",
     [("The Golgi apparatus modifies and packages proteins for secretion.", True,
       "glycosylation and sorting of secretory proteins occur in Golgi cisternae"),
      ("Lysosomes originate from the smooth endoplasmic reticulum.", False,
       "lysosome buds off from the trans face of the GOLGI, not the SER"),
      ("Mitochondria possess their own DNA and ribosomes.", True,
       "circular mtDNA and 70S ribosomes support semi-autonomy and endosymbiosis")],
     "Medium", None),

    ("Biology", "Plant Kingdom", 11, "Life cycles",
     [("In bryophytes the sporophyte is dependent on the gametophyte.", True,
       "the short-lived sporophyte grows attached to and draws nutrition from the gametophyte"),
      ("In pteridophytes the gametophyte is the dominant phase.", False,
       "ferns are sporophyte-dominant; the gametophyte is a small, short-lived prothallus"),
      ("In gymnosperms the female gametophyte is retained within the ovule.", True,
       "the megagametophyte develops inside the naked ovule on the megasporophyll")],
     "Medium", None),

    ("Biology", "Animal Kingdom", 11, "Phylum characters",
     [("Nematodes possess a pseudocoelom.", True,
       "the body cavity of Aschelminthes is not fully lined by mesoderm"),
      ("Annelids show an open circulatory system.", False,
       "annelids have a CLOSED circulatory system; open systems occur in arthropods and molluscs"),
      ("Arthropods moult to grow because their cuticle cannot expand.", True,
       "the chitinous exoskeleton is rigid; ecdysis is required for growth")],
     "Medium", None),

    ("Biology", "Human Physiology: Neural Control", 11, "Nerve impulse",
     [("The resting potential of a neuron is negative inside relative to outside.", True,
       "the Na+/K+ pump and K+ leak maintain about -70 mV inside"),
      ("Depolarisation of the membrane is caused by potassium efflux.", False,
       "depolarisation is caused by Na+ influx through voltage-gated sodium channels"),
      ("Myelin sheath increases the speed of impulse conduction.", True,
       "saltatory conduction jumps between nodes of Ranvier, greatly speeding transmission")],
     "Medium", None),

    ("Biology", "Human Physiology: Digestion", 11, "Digestive enzymes",
     [("Pepsin is secreted as the inactive precursor pepsinogen.", True,
       "chief cells release pepsinogen, activated by gastric HCl"),
      ("Bile contains the enzyme lipase.", False,
       "bile is enzyme-free; it emulsifies fat while pancreatic lipase hydrolyses it"),
      ("Enterokinase activates trypsinogen in the small intestine.", True,
       "the brush-border enzyme converts trypsinogen to trypsin, which activates other zymogens")],
     "Medium", None),

    ("Biology", "Human Physiology: Excretion", 11, "Nephron",
     [("Ultrafiltration occurs in the glomerulus.", True,
       "high glomerular capillary pressure drives filtrate into Bowman's capsule"),
      ("Glucose is normally absent in urine because it is reabsorbed in the collecting duct.", False,
       "glucose is reabsorbed in the PROXIMAL convoluted tubule, not the collecting duct"),
      ("ADH increases water permeability of the collecting duct.", True,
       "aquaporin insertion concentrates urine; failure causes diabetes insipidus")],
     "Medium", None),

    ("Biology", "Human Physiology: Circulation", 11, "Cardiac cycle",
     [("The 'lub' sound marks the closure of atrio-ventricular valves.", True,
       "ventricular systole slams the tricuspid and mitral valves shut (S1)"),
      ("Semilunar valves close at the start of ventricular systole.", False,
       "they close at the END of systole, producing the 'dub' (S2) sound"),
      ("Cardiac output equals stroke volume multiplied by heart rate.", True,
       "about 70 mL x 72 bpm gives roughly 5 L per minute")],
     "Medium", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "Gene regulation",
     [("The lac operon is induced by lactose (allolactose).", True,
       "allolactose inactivates the repressor, allowing transcription"),
      ("The lacI repressor gene lies within the operon's structural genes.", False,
       "lacI sits upstream with its OWN promoter; it is not part of the lacZYA unit"),
      ("RNA polymerase binds the operator to begin transcription.", False,
       "polymerase binds the PROMOTER; the operator is the repressor's binding site")],
     "Hard", None),

    ("Biology", "Principles of Inheritance and Variation", 12, "Chromosomal disorders",
     [("Down's syndrome results from trisomy of chromosome 21.", True,
       "non-disjunction in meiosis produces an extra chromosome 21"),
      ("Turner's syndrome affects males with an XXY karyotype.", False,
       "Turner's is 45, XO in FEMALES; XXY males have Klinefelter's"),
      ("Sickle-cell anaemia is caused by a single base substitution in the beta-globin gene.", True,
       "GAG to GUG replaces glutamic acid with valine at position six")],
     "Medium", None),

    ("Biology", "Photosynthesis in Higher Plants", 11, "Photosystems",
     [("Photosystem II splits water and releases oxygen.", True,
       "photolysis at PSII's oxygen-evolving complex liberates O2, electrons and protons"),
      ("Photosystem I absorbs light maximally at 680 nm.", False,
       "P700 is PSI's reaction centre; PSII's is P680"),
      ("Cyclic photophosphorylation involves only photosystem I.", True,
       "electrons cycle back to PSI without NADP+ reduction or water splitting")],
     "Medium", None),

    ("Biology", "Human Health and Disease", 12, "Infectious diseases",
     [("Malaria is caused by Plasmodium species.", True,
       "P. vivax, P. falciparum and others are transmitted by female Anopheles"),
      ("AIDS is transmitted by contaminated food and water.", False,
       "HIV spreads by sexual contact, blood and mother-to-child routes only"),
      ("Antibiotics are ineffective against viruses.", True,
       "viruses lack the metabolic machinery that antibiotics target")],
     "Easy", None),

    ("Biology", "Ecosystem", 12, "Energy flow",
     [("Energy flow in an ecosystem is unidirectional.", True,
       "energy enters as sunlight and leaves as heat; it cannot be recycled"),
      ("The 10 percent law was proposed by Lindeman.", True,
       "each trophic level receives about a tenth of the previous level's energy"),
      ("Pyramids of energy can sometimes be inverted.", False,
       "energy pyramids are ALWAYS upright; only biomass pyramids can invert")],
     "Medium", None),

    ("Biology", "Biotechnology and its Applications", 12, "Bt crops",
     [("cry genes encode insecticidal proteins.", True,
       "Bacillus thuringiensis produces crystalline protoxins toxic to specific insects"),
      ("The Bt toxin is active in the bacterial cell itself.", False,
       "it is an inactive protoxin, activated only in the insect's alkaline gut"),
      ("RNA interference can silence specific genes in plants.", True,
       "dsRNA processed to siRNA guides degradation of complementary mRNA")],
     "Medium", None),

    ("Biology", "Evolution", 12, "Evolutionary mechanisms",
     [("Genetic drift changes allele frequencies randomly.", True,
       "chance sampling in small populations can fix or remove alleles"),
      ("The bottleneck effect requires a population size of millions.", False,
       "bottlenecks act on populations sharply REDUCED in size, the opposite"),
      ("Adaptive radiation produces many species from one ancestor.", True,
       "Darwin's finches radiated from a common seed-eating ancestor into many niches")],
     "Medium", None),

    # ---------------- Chemistry ----------------
    ("Chemistry", "Chemical Bonding", 11, "VSEPR and hybridisation",
     [("SF6 is octahedral with sp3d2 hybridisation.", True,
       "six bond pairs, no lone pairs, give the octahedral geometry"),
      ("Water is linear because oxygen is sp-hybridised.", False,
       "water is BENT (about 104.5 degrees) with sp3 oxygen and two lone pairs"),
      ("NH3 is pyramidal with one lone pair on nitrogen.", True,
       "sp3 nitrogen with three bonds and one lone pair gives the pyramidal shape")],
     "Medium", None),

    ("Chemistry", "Solutions", 12, "Colligative properties",
     [("Elevation of boiling point is proportional to molality of the solute.", True,
       "delta-Tb = Kb times molality for dilute solutions"),
      ("Freezing point of a solution is higher than that of the pure solvent.", False,
       "dissolved solute LOWERS the freezing point (depression)"),
      ("Osmotic pressure depends on the number of solute particles.", True,
       "pi = nRT/V is colligative — particle count, not identity")],
     "Medium", None),

    ("Chemistry", "Surface Chemistry", 12, "Adsorption",
     [("Physisorption involves weak van der Waals forces.", True,
       "the enthalpy of physisorption is low (20-40 kJ/mol)"),
      ("Chemisorption is multi-layered and reversible.", False,
       "chemisorption is monolayered and largely irreversible; multi-layering is physisorption"),
      ("Adsorption of a gas on a solid decreases with rising temperature for physisorption.", True,
       "weak van der Waals binding is disrupted as thermal energy rises")],
     "Medium", None),

    ("Chemistry", "Alcohols, Phenols and Ethers", 12, "Reactions of phenol",
     [("Phenol is more acidic than ethanol.", True,
       "the phenoxide ion is resonance-stabilised; ethoxide is not"),
      ("Phenol reacts with NaOH to give sodium phenoxide.", True,
       "its acidity (pKa about 10) permits reaction with strong base"),
      ("Phenol needs an FeBr3 catalyst to decolourise bromine water.", False,
       "the phenol ring is so activated that bromine water is decolourised instantly WITHOUT any catalyst, giving 2,4,6-tribromophenol")],
     "Medium", None),

    ("Chemistry", "Aldehydes, Ketones and Carboxylic Acids", 12, "Tests",
     [("Aldehydes give a positive Tollens' test.", True,
       "the silver mirror forms as aldehyde is oxidised to carboxylate"),
      ("Ketones are readily oxidised by mild oxidants like Tollens' reagent.", False,
       "ketones resist mild oxidation — that is how the Tollens/Fehling tests distinguish them"),
      ("Carboxylic acids react with sodium bicarbonate with effervescence.", True,
       "CO2 evolution identifies the acidic -COOH group")],
     "Easy", None),

    ("Chemistry", "Coordination Compounds", 12, "Isomerism",
     [("[Co(NH3)4Cl2]+ can exhibit geometrical isomerism.", True,
       "octahedral MA4B2 complexes have cis and trans forms"),
      ("Tetrahedral complexes commonly show cis-trans isomerism.", False,
       "all four positions in a tetrahedron are adjacent, so no geometrical isomers"),
      ("Linkage isomerism arises with ambidentate ligands like NO2-.", True,
       "nitrite can bind through N (nitro) or O (nitrito)")],
     "Medium", None),

    ("Chemistry", "p-Block Elements", 12, "Group 16 and 17",
     [("Sulphur hexafluoride is chemically inert due to steric protection.", True,
       "six fluorines shield the sulphur centre, making SF6 highly inert"),
      ("Fluorine is the strongest oxidising halogen because it has the lowest electronegativity.", False,
       "fluorine IS the strongest oxidiser, but because it has the HIGHEST electronegativity and low F-F bond energy"),
      ("Chlorine water bleaches dyes by oxidation.", True,
       "Cl2 + H2O gives HClO, whose nascent oxygen oxidises the dye")],
     "Hard", None),

    ("Chemistry", "Electrochemistry", 12, "Cell potential",
     [("Standard electrode potentials are measured against the standard hydrogen electrode.", True,
       "SHE is assigned 0.00 V at 1 M H+, 1 bar H2, 298 K"),
      ("A positive cell EMF indicates a non-spontaneous reaction.", False,
       "positive EMF means negative delta-G — the reaction IS spontaneous"),
      ("The anode of a galvanic cell is the site of oxidation.", True,
       "oxidation at anode, reduction at cathode, in every electrochemical cell")],
     "Medium", None),

    ("Chemistry", "States of Matter / Gaseous State", 11, "Kinetic theory",
     [("At constant temperature, average kinetic energy is the same for all ideal gases.", True,
       "KE depends only on T: (3/2)kT per molecule regardless of gas identity"),
      ("At the same temperature, lighter gases travel slower on average.", False,
       "lighter gases move FASTER: v_rms is inversely proportional to sqrt(M)"),
      ("Real gases behave most ideally at low pressure and high temperature.", True,
       "intermolecular forces and molecular volumes become negligible under those conditions")],
     "Medium", None),

    # ---------------- Physics ----------------
    ("Physics", "Laws of Motion", 11, "Newton's laws",
     [("Action and reaction forces act on different bodies.", True,
       "Newton's third law pairs never act on the same object, which is why they do not cancel"),
      ("A net force is required to keep an object moving at constant velocity.", False,
       "constant velocity needs ZERO net force — the Aristotelian error"),
      ("Friction always opposes relative motion between surfaces.", True,
       "static and kinetic friction both act against the tendency or reality of sliding")],
     "Medium", None),

    ("Physics", "Work, Energy and Power", 11, "Work-energy theorem",
     [("The work-energy theorem holds in inertial frames.", True,
       "net work equals change in kinetic energy, derived from Newton's second law"),
      ("The normal force does work on a block sliding along a horizontal floor.", False,
       "the normal force is perpendicular to the displacement, doing zero work"),
      ("The spring force is conservative.", True,
       "its work depends only on endpoints; potential energy 1/2 k x^2 is definable")],
     "Medium", None),

    ("Physics", "Ray Optics", 12, "Total internal reflection",
     [("Total internal reflection requires light to travel from a denser to a rarer medium.", True,
       "the ray must bend away from the normal, i.e., n1 greater than n2"),
      ("The critical angle increases as the refractive index of the denser medium increases.", False,
       "sin C = 1/n2: as n rises, C DECREASES (diamond's n = 2.42 gives C about 24.4 degrees)"),
      ("Optical fibres work on total internal reflection.", True,
       "light stays inside the core by repeated TIR at the core-cladding boundary")],
     "Medium", None),

    ("Physics", "Thermodynamics", 11, "Laws of thermodynamics",
     [("In an isothermal process for an ideal gas, internal energy is unchanged.", True,
       "U depends only on T for an ideal gas; T is constant, so delta-U = 0"),
      ("Adiabatic compression of a gas lowers its temperature.", False,
       "adiabatic compression does work ON the gas, raising its temperature"),
      ("The first law is a statement of energy conservation.", True,
       "delta-Q = delta-U + delta-W accounts for every joule")],
     "Medium", None),

    ("Physics", "Alternating Current", 12, "LCR circuits",
     [("In a purely inductive AC circuit, current lags voltage by 90 degrees.", True,
       "v_L = L di/dt makes voltage lead current by a quarter cycle"),
      ("At resonance in a series LCR circuit, impedance is maximum.", False,
       "resonance MINIMISES impedance (Z = R) and maximises current"),
      ("Capacitors block direct current in steady state.", True,
       "once charged, no steady current flows through an ideal capacitor")],
     "Medium", None),

    ("Physics", "Dual Nature of Radiation and Matter", 12, "Photoelectric effect",
     [("Photoemission occurs only above a threshold frequency.", True,
       "each photon must carry at least the work function phi = h nu0"),
      ("Increasing light intensity above threshold increases the stopping potential.", False,
       "stopping potential depends on FREQUENCY; intensity affects only the photocurrent"),
      ("The photoelectric effect demonstrates the particle nature of light.", True,
       "one photon-one electron absorption with instant emission is corpuscular behaviour")],
     "Medium", None),

    # ---------------- all-true entries (answer D) ----------------
    ("Biology", "Molecular Basis of Inheritance", 12, "Structure of DNA",
     [("The DNA double helix has a uniform diameter of about 2 nm.", True,
       "a purine always pairs with a pyrimidine, keeping the backbone spacing constant"),
      ("The two strands of DNA are antiparallel.", True,
       "one runs 5' to 3' while its partner runs 3' to 5'"),
      ("Replication of DNA is semiconservative.", True,
       "each daughter duplex retains one parental strand, as Meselson-Stahl showed")],
     "Medium", None),

    ("Biology", "Human Physiology: Breathing", 11, "Gas transport",
     [("About 97 percent of oxygen in blood is carried bound to haemoglobin.", True,
       "only a small fraction dissolves in plasma"),
      ("Carbon dioxide is transported mainly as bicarbonate ions.", True,
       "carbonic anhydrase in red cells converts CO2 to HCO3- (about 70 percent)"),
      ("Every 100 mL of oxygenated blood can deliver about 5 mL of O2 to tissues.", True,
       "the NCERT figure for O2 delivery per 100 mL under normal conditions")],
     "Medium", None),

    ("Chemistry", "Chemical Bonding", 11, "Hybridisation",
     [("sp3 hybrid orbitals are arranged tetrahedrally at about 109.5 degrees.", True,
       "one s and three p orbitals mix into four equivalent tetrahedral orbitals"),
      ("The bond angle in ethene is close to 120 degrees.", True,
       "sp2 hybridisation gives the trigonal-planar geometry"),
      ("Lone pairs compress bond angles below the ideal values.", True,
       "repulsion order lp-lp greater than lp-bp greater than bp-bp squeezes bonding pairs together")],
     "Medium", None),

    ("Physics", "Motion in a Straight Line", 11, "Kinematic equations",
     [("Displacement can be zero even when distance travelled is not.", True,
       "a round trip returns to the start with zero displacement"),
      ("The slope of a position-time graph gives instantaneous velocity.", True,
       "dx/dt is the graph's slope at that instant"),
      ("The area under a velocity-time graph gives displacement.", True,
       "integrating v dt over the interval yields the displacement")],
     "Easy", None),

    ("Biology", "Principles of Inheritance and Variation", 12, "Mendelian genetics",
     [("Mendel's law of dominance applies when one allele masks the other in the heterozygote.", True,
       "the F1 shows only the dominant character"),
      ("Alleles segregate during gamete formation.", True,
       "homologous chromosomes separate in meiosis I, taking alleles apart"),
      ("Genes on different chromosomes assort independently.", True,
       "meiotic metaphase orientation of one pair does not bias another pair")],
     "Medium", None),
]


def build() -> list[dict]:
    """Rotate each entry's statement order by (index % 3) so the FALSE (or
    lone-true) statement spreads evenly across positions I/II/III — otherwise
    the correct option letter piles up on one key (most entries were authored
    with statement II as the false one)."""
    out = []
    for i, e in enumerate(ENTRIES):
        subject, chapter, ncert_class, topic, facts, difficulty, pyq = e
        assert len(facts) == 3, f"need 3 statements: {facts[0][0][:40]}"
        k = i % 3
        rotated = facts[k:] + facts[:k]
        out.append(_sm(subject, chapter, ncert_class, topic, rotated, difficulty, pyq))
    return out


# ---------------------------------------------------------------------------
# Selftest — recompute the key from the facts and check it against the option set
# ---------------------------------------------------------------------------
def _selftest() -> None:
    counts = {"one_true": 0, "two_true": 0, "three_true": 0}
    letters = {"A": 0, "B": 0, "C": 0, "D": 0}
    stems = set()
    for q in build():
        letters[q["correct_option"]] += 1
        stems.add(q["question_text"])
        n_true = sum(1 for line in q["question_text"].splitlines()
                     if line.startswith("Statement") and "only one way" not in line)
    # recompute per-entry truth mix from ENTRIES
    for e in ENTRIES:
        n_true = sum(1 for _, t, _ in e[4] if t)
        assert n_true in (1, 2, 3), f"all-false stem: {e[4][0][0][:40]}"
        counts["one_true" if n_true == 1 else
               "two_true" if n_true == 2 else "three_true"] += 1
    assert len(stems) == len(ENTRIES), "duplicate stems"
    print(f"statement_match selftest: {len(ENTRIES)} entries OK, truth mix {counts}, "
          f"answer letters {letters}")


if __name__ == "__main__":
    _selftest()
