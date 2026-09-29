"""Assertion-Reason questions (P1 format extension).

Format: question_text contains "Assertion (A):" and "Reason (R):", followed by
the canonical four-option NEET set. Each entry's truth values are hand-verified
against NCERT (this format CANNOT be safely auto-generated: the A/B/C/D verdict
depends on knowing exactly which statements are true and whether R explains A).

Entry: (subject, chapter, ncert_class, topic, assertion, reason, verdict,
        explanation, difficulty, pyq_or_None)
verdict: "A" both true, R explains A | "B" both true, R does not explain A |
         "C" A true, R false       | "D" A false, R true

The options are NOT shuffled (canonical order), so letters mean the same thing
in every AR question — matching real NEET AR items.

Run selftest:  python demo_set_qns/generators/assertion_reason.py
"""

AR_OPTIONS = [
    "Both assertion and reason are true, and the reason is the correct explanation of the assertion",
    "Both assertion and reason are true, but the reason is not the correct explanation of the assertion",
    "The assertion is true, but the reason is false",
    "The assertion is false, but the reason is true",
]


def _ar(subject: str, chapter: str, ncert_class: int, topic: str,
        assertion: str, reason: str, verdict: str, explanation: str,
        difficulty: str, pyq) -> dict:
    stem = (f"Assertion (A): {assertion}\n"
            f"Reason (R): {reason}\n"
            f"Which of the following is correct?")
    return {
        "id": "", "subject": subject, "chapter": chapter,
        "ncert_class": ncert_class, "topic": topic,
        "difficulty": difficulty, "bloom_level": "analysis",
        "question_text": stem, "options": list(AR_OPTIONS),
        "correct_option": verdict, "explanation": explanation,
        "common_wrong_reasoning": None, "neet_pyq_year": pyq,
        "diagram": None, "type": "assertion_reason",
    }


ENTRIES: list[tuple] = [
    # ---------------- Biology: Molecular Basis ----------------
    ("Biology", "Molecular Basis of Inheritance", 12, "Structure of DNA",
     "In double-stranded DNA, the amount of adenine always equals the amount of thymine.",
     "Adenine pairs with thymine through two hydrogen bonds in the Watson-Crick base-pairing scheme.",
     "A",
     "Base pairing is complementary: A pairs only with T (two H-bonds) and G only with C (three H-bonds). Therefore each A on one strand dictates a T opposite it, making A = T and G = C — Chargaff's rule. The reason directly explains the assertion.",
     "Easy", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "Transcription and processing",
     "Eukaryotic mRNA must undergo processing before it can be translated.",
     "The eukaryotic transcription unit contains introns that do not code for protein.",
     "A",
     "Because eukaryotic genes contain non-coding introns, the primary transcript (hnRNA) must be spliced to remove them, then capped (7-methyl guanosine) and polyadenylated. Only the processed mRNA reaches the cytosol for translation. The presence of introns is exactly why processing is needed.",
     "Medium", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "DNA replication",
     "Replication of the bacterial chromosome proceeds in one direction only around the circular molecule.",
     "DNA polymerase can add nucleotides only in the 5' to 3' direction.",
     "D",
     "The assertion is false: replication of E. coli DNA is BIDIRECTIONAL from a single origin. The reason is true — polymerase's 5'->3' constraint is real — but it is solved by two replication forks moving opposite ways, each synthesising leading and lagging strands. The polymerase constraint does not force unidirectional replication.",
     "Medium", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "Genetic code",
     "The genetic code is described as degenerate.",
     "There are 64 codons but only 20 amino acids are generally used in proteins.",
     "A",
     "Degeneracy means several codons specify the same amino acid. With 64 triplet codons (61 sense + 3 stop) mapping onto 20 amino acids, some amino acids must share codons (e.g., leucine has six). The 64-vs-20 arithmetic is precisely what makes the code degenerate.",
     "Easy", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "Translation",
     "tRNA acts as an adapter molecule during protein synthesis.",
     "The anticodon loop of tRNA reads the mRNA codon while its 3' end carries the corresponding amino acid.",
     "A",
     "Crick's adapter hypothesis: a molecule is needed that can simultaneously 'read' the nucleic-acid message and hold an amino acid. tRNA does exactly this — anticodon-codon pairing at one end, aminoacylation at the 3' CCA end. The reason describes the dual structure that makes tRNA the adapter.",
     "Medium", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "Lac operon",
     "The lac repressor is produced continuously, whether or not lactose is present.",
     "The lacI gene has its own promoter and is expressed constitutively, independent of the operon's structural genes.",
     "A",
     "Repressor production is constitutive because lacI sits upstream with its own promoter, transcribed constantly at low level. Regulation then happens at the protein level: allolactose inactivates the repressor only when lactose is present. The reason explains why repressor supply is constant.",
     "Hard", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "Discovery of genetic material",
     "Hershey and Chase could label phage DNA and protein separately using radioactive phosphorus and sulphur.",
     "Sulphur is present in amino acids such as cysteine and methionine but absent from DNA, while phosphorus is present in DNA but absent from phage protein.",
     "A",
     "The differential labelling works BECAUSE of the chemical exclusivity: 35S marks protein only, 32P marks DNA only. Blending removed the labelled protein coats while 32P entered cells and appeared in progeny phage — proving DNA is the genetic material. The reason is the chemical basis of the whole experiment.",
     "Hard", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "DNA replication",
     "Okazaki fragments on the lagging strand are ultimately joined into one continuous strand.",
     "DNA polymerase can synthesise only in the 5' to 3' direction, so the lagging strand must be made in short pieces.",
     "A",
     "Because polymerase cannot work 3'->5', the lagging strand is built backwards as short Okazaki fragments (each 5'->3'); DNA ligase then seals the nicks between them. The polarity constraint is exactly why fragments exist and why ligase is needed.",
     "Medium", None),

    ("Biology", "Molecular Basis of Inheritance", 12, "Translation",
     "Aminoacylation of tRNA is essential for translation.",
     "The amino acid must be covalently linked to its tRNA so that codon-anticodon recognition places the correct amino acid into the growing polypeptide.",
     "A",
     "The ribosome checks codon-anticodon pairing, not the amino acid itself; the amino acid's identity rides entirely on its tRNA. Without aminoacylation (by aminoacyl-tRNA synthetase), the adapter carries no cargo and peptide bonds cannot form correctly.",
     "Medium", None),

    # ---------------- Biology: Cell Cycle ----------------
    ("Biology", "Cell Cycle and Cell Division", 11, "Meiosis I",
     "Crossing over occurs during the pachytene substage of prophase I.",
     "Recombination nodules appear between homologous chromosomes at pachytene, marking the sites where segment exchange occurs.",
     "A",
     "Pachytene is the crossing-over stage: the synaptonemal complex (formed in zygotene) holds homologues in intimate pairing, and recombination nodules mediate the exchange of non-sister chromatid segments. The reason identifies the structural basis of the event.",
     "Medium", None),

    ("Biology", "Cell Cycle and Cell Division", 11, "Meiosis I",
     "The reduction in chromosome number happens during meiosis I, not meiosis II.",
     "Anaphase I separates homologous chromosomes while anaphase II separates sister chromatids.",
     "A",
     "Reductional division is meiosis I: homologous pairs (each still two chromatids) are pulled apart at anaphase I, halving the number. Meiosis II is equational — sister chromatids separate. The anaphase distinction IS the mechanism behind the reduction.",
     "Medium", None),

    ("Biology", "Cell Cycle and Cell Division", 11, "Mitosis",
     "Chromosomes are easiest to study under the microscope during metaphase.",
     "At metaphase, chromosomes are fully condensed and aligned at the cell's equatorial plane.",
     "A",
     "Maximal condensation occurs by metaphase; the metaphase plate arrangement makes counting and morphology (arm ratios) unambiguous — the reason is why the assertion holds. Colchicine-based karyotyping exploits exactly this stage.",
     "Easy", None),

    ("Biology", "Cell Cycle and Cell Division", 11, "Meiosis significance",
     "Meiosis is described as the mechanism that conserves a species' chromosome number across generations.",
     "Meiosis halves the chromosome number in gametes, which is restored at fertilisation.",
     "A",
     "Diploid organisms would double their chromosome number every generation without a reduction step. Meiosis makes gametes haploid; syngamy restores diploidy — the two together form a precise cycle. The reason is the direct mechanism of the conservation.",
     "Easy", None),

    # ---------------- Biology: Photosynthesis ----------------
    ("Biology", "Photosynthesis in Higher Plants", 11, "C4 pathway",
     "C4 plants generally outperform C3 plants in hot, dry climates.",
     "The C4 pathway concentrates CO2 around RuBisCO in bundle-sheath cells, strongly suppressing photorespiration.",
     "A",
     "At high temperature and low CO2 (stomata partly closed), RuBisCO's oxygenase activity wastes carbon in C3 plants. C4 anatomy and biochemistry pump CO2 to the bundle sheath, keeping RuBisCO saturated with CO2. The suppression of photorespiration is exactly why C4 plants win in those climates.",
     "Medium", None),

    ("Biology", "Photosynthesis in Higher Plants", 11, "Light reaction",
     "Cyclic photophosphorylation produces ATP but neither NADPH nor oxygen.",
     "In cyclic electron flow, electrons ejected from PSI return to it without reducing NADP+, and water is not split.",
     "A",
     "Cyclic flow uses only PSI: electrons cycle from ferredoxin back through the cytochrome b6f complex, pumping protons and making ATP, but NADP+ is never reduced and PSII never splits water. The closed loop is the reason no NADPH or O2 appears.",
     "Medium", None),

    ("Biology", "Photosynthesis in Higher Plants", 11, "Photorespiration",
     "RuBisCO can act both as a carboxylase and as an oxygenase.",
     "CO2 and O2 compete for the same active site of RuBisCO.",
     "A",
     "RuBisCO's active site accepts either CO2 (carboxylation -> 2 PGA) or O2 (oxygenation -> phosphoglycolate, leading to photorespiration). Relative concentrations of the two gases decide the outcome — the competition at one site is the mechanistic basis of the dual activity.",
     "Medium", None),

    ("Biology", "Photosynthesis in Higher Plants", 11, "CAM pathway",
     "CAM plants open their stomata at night.",
     "Opening stomata in darkness lets them fix CO2 into organic acids while losing far less water than daytime opening would cost.",
     "A",
     "Crassulacean acid metabolism: nocturnal CO2 uptake (via PEP carboxylase) stores acids in vacuoles for daytime Calvin-cycle use. Desert plants minimise transpiration because night air is cool and humid — the water-saving logic explains the timing.",
     "Easy", None),

    ("Biology", "Photosynthesis in Higher Plants", 11, "Photosystems",
     "Photosystem I is located mostly in the grana membranes of the chloroplast.",
     "Stroma lamellae lack photosystem II and therefore cannot split water.",
     "D",
     "The assertion is false: PSI is found mostly in the STROMA LAMELLAE (unstacked regions), while PSII sits mainly in the grana. The reason is true — stroma lamellae lack PSII — and it is in fact why cyclic photophosphorylation occurs there, but the assertion as stated is wrong.",
     "Hard", None),

    # ---------------- Biology: Human Physiology ----------------
    ("Biology", "Excretory Products and their Elimination", 11, "ADH and water balance",
     "Vasopressin secretion rises when the body is dehydrated.",
     "Vasopressin promotes water reabsorption in the distal tubule and collecting duct, concentrating the urine.",
     "A",
     "Dehydration raises plasma osmolarity, detected by hypothalamic osmoreceptors, which drives ADH release. ADH inserts aquaporins in the collecting duct so more water is reclaimed — the kidney's main response to water shortage. The reason is the physiological effect that makes the assertion true.",
     "Easy", None),

    ("Biology", "Body Fluids and Circulation", 11, "Heart structure",
     "The ventricular walls are much thicker than the atrial walls.",
     "Ventricles must pump blood at high pressure to the lungs and to the entire body.",
     "A",
     "Wall thickness tracks the pressure each chamber generates. Atria only push blood a short distance into ventricles; the left ventricle in particular drives systemic pressure — hence its thick muscular wall. The pressure requirement explains the structure.",
     "Easy", None),

    ("Biology", "Digestion and Absorption", 11, "Bile",
     "Bile is essential for the efficient digestion of fats.",
     "Bile salts emulsify fats into small micelles, greatly increasing the surface area available to pancreatic lipase.",
     "A",
     "Lipase works only on lipid-water surfaces. Emulsification by bile salts multiplies that surface, accelerating triglyceride hydrolysis. Bile itself contains no enzyme — its necessity is purely the emulsifying function described in the reason.",
     "Easy", None),

    ("Biology", "Digestion and Absorption", 11, "Absorption",
     "Glucose absorption in the intestine can proceed against its concentration gradient.",
     "Glucose is co-transported with sodium ions, driven by the sodium-potassium pump's gradient.",
     "A",
     "SGLT1 symports 2 Na+ with each glucose; the Na+ gradient itself is maintained by the basolateral Na+/K+-ATPase, spending ATP. This secondary active transport is precisely how glucose can accumulate against its gradient.",
     "Hard", None),

    ("Biology", "Body Fluids and Circulation", 11, "Blood groups",
     "Individuals with the AB blood group are called universal recipients.",
     "AB erythrocytes carry both A and B antigens, and the plasma therefore contains no anti-A or anti-B antibodies.",
     "A",
     "Transfusion reactions are caused by recipient antibodies attacking donor red cells. Because AB plasma has neither anti-A nor anti-B antibodies, it will not agglutinate any donor RBC type. The antibody situation is exactly why AB individuals can receive any blood.",
     "Medium", None),

    ("Biology", "Neural Control and Coordination", 11, "Nerve impulse",
     "During an action potential, sodium channels open before potassium channels.",
     "Voltage-gated sodium channels have a lower activation threshold than voltage-gated potassium channels.",
     "A",
     "Depolarisation to threshold first opens fast Na+ channels (rising phase); K+ channels open more slowly (falling phase). The timing difference in gating is what produces the spike sequence — the reason explains the order of events.",
     "Medium", None),

    ("Biology", "Chemical Coordination and Integration", 11, "Thyroid disorders",
     "Hypothyroidism in children can cause stunted growth and intellectual disability.",
     "Thyroid hormones are required for normal skeletal growth and neural maturation.",
     "A",
     "T3/T4 drive BMR, bone growth and brain development; deficiency in infancy produces cretinism. The developmental roles of the hormones explain the clinical picture — the reason is the mechanism behind the assertion.",
     "Medium", None),

    ("Biology", "Breathing and Exchange of Gases", 11, "Respiratory pigments",
     "Haemoglobin's oxygen affinity decreases in actively metabolising tissues.",
     "Higher CO2, H+ and temperature in tissues shift the oxygen dissociation curve to the right (Bohr effect).",
     "A",
     "Tissues producing CO2 and H+ are precisely where O2 must be unloaded; the Bohr right-shift lowers affinity there. The changed chemical environment is the cause of the reduced affinity — the reason explains the assertion.",
     "Hard", None),

    ("Biology", "Body Fluids and Circulation", 11, "Disorders",
     "Asthma is classified as an autoimmune disease.",
     "Asthma attacks involve inflammation and narrowing of the bronchi, causing difficulty in breathing.",
     "D",
     "The assertion is false: asthma is an allergic/inflammatory airway disorder, not autoimmunity (autoimmune examples: rheumatoid arthritis, SLE). The reason is a true description of the asthma attack, but the condition's immunology does not make it autoimmune.",
     "Easy", None),

    ("Biology", "Human Health and Disease", 12, "Immunity",
     "Injection of preformed antibodies provides instantly acting but short-lived protection.",
     "Passive immunity uses ready-made antibodies that neutralise the antigen but do not establish memory cells.",
     "A",
     "Antiserum or immunoglobulin injections act immediately because the effector molecules are already present, but no clonal selection or memory is generated, so protection fades as the injected antibodies are catabolised. The absence of memory is why the protection is short-lived.",
     "Medium", None),

    # ---------------- Biology: Evolution / Biotech / Reproduction ----------------
    ("Biology", "Evolution", 12, "Mechanisms of evolution",
     "Antibiotic resistance in bacteria illustrates directional selection.",
     "The drug kills susceptible bacteria, leaving resistant variants to reproduce disproportionately.",
     "A",
     "The antibiotic is the selective agent; the population's mean phenotype shifts toward resistance because only resistant cells leave offspring. Differential survival with a clear environmental pressure is the definition of directional selection.",
     "Medium", None),

    ("Biology", "Evolution", 12, "Hardy-Weinberg principle",
     "A population that is in Hardy-Weinberg equilibrium is not evolving at that locus.",
     "Equilibrium requires random mating, a very large population, and no mutation, migration or selection.",
     "A",
     "Allele frequencies stay constant only when the five equilibrium conditions hold; change in allele frequency IS evolution. The conditions in the reason are what make the frequency stability — and hence the non-evolution — true.",
     "Medium", None),

    ("Biology", "Biotechnology and its Applications", 12, "Bt crops",
     "Bt cotton is protected against bollworm insects.",
     "It carries cry genes from Bacillus thuringiensis, whose protoxin becomes toxic in the alkaline gut of the insect.",
     "A",
     "The cry protein is produced as an inactive protoxin; the insect's alkaline gut solubilises and activates it, killing the bollworm. The gene source and activation mechanism are exactly why the plant is protected.",
     "Medium", None),

    ("Biology", "Biotechnology and its Applications", 12, "RNA interference",
     "RNA interference serves as a cellular defence in eukaryotes.",
     "Double-stranded RNA is processed into small interfering RNAs that direct the degradation of complementary target RNA.",
     "A",
     "The siRNA-guided RISC complex destroys viral or transposon RNA with matching sequence — antiviral and genome-protection role. The mechanism in the reason is how the defence works.",
     "Hard", None),

    ("Biology", "Human Reproduction", 12, "Male reproductive system",
     "The testes are held outside the abdominal cavity in the scrotum.",
     "Spermatogenesis requires a temperature about 2 to 2.5 degrees C below normal core body temperature.",
     "A",
     "The scrotal position provides the cooler environment meiotic cells need; failure of descent (cryptorchidism) causes sterility. The thermal requirement is the reason for the anatomical arrangement.",
     "Easy", None),

    ("Biology", "Human Reproduction", 12, "Female reproductive system",
     "The corpus luteum is essential for maintaining early pregnancy.",
     "The corpus luteum secretes progesterone, which maintains the endometrium needed for implantation and early development.",
     "A",
     "Until the placenta takes over (second trimester), the corpus luteum is the progesterone source; withdrawal would cause endometrial breakdown and loss of pregnancy. The hormone function explains the assertion.",
     "Medium", None),

    ("Biology", "Reproductive Health", 12, "Assisted reproduction",
     "Intracytoplasmic sperm injection can help men with very low sperm counts father children.",
     "ICSI injects a single sperm directly into the cytoplasm of an egg, bypassing natural fertilisation barriers.",
     "A",
     "Where sperm number or motility is inadequate for even IVF insemination, ICSI needs exactly one sperm per egg. The direct-injection technique is what makes low counts surmountable.",
     "Medium", None),

    ("Biology", "Biotechnology: Principles and Processes", 12, "PCR",
     "The polymerase chain reaction can amplify DNA a billionfold in a few hours.",
     "Each PCR cycle doubles the amount of target DNA, and cycles are repeated many times.",
     "A",
     "Exponential amplification: 2^n copies after n cycles; ~30 cycles give ~10^9. The doubling-per-cycle mechanism in the reason is precisely what produces the billionfold outcome.",
     "Medium", None),

    ("Biology", "Biotechnology: Principles and Processes", 12, "Recombinant insulin",
     "Human insulin used by diabetic patients was, before recombinant DNA technology, obtained from animal pancreases.",
     "Recombinant DNA technology now produces human insulin inside bacterial cells.",
     "B",
     "Both statements are true: porcine/bovine insulin preceded the recombinant product (Humulin, from engineered E. coli). But the reason describes the current production method — it does not explain WHY animal pancreases were the earlier source; the earlier source existed simply because no alternative existed then.",
     "Medium", None),

    ("Biology", "Biotechnology and its Applications", 12, "Gene therapy",
     "Gene therapy involves introducing a functional gene into a patient's cells.",
     "In ADA deficiency, the defective gene cannot produce functional adenosine deaminase enzyme.",
     "B",
     "Both statements are true, but the reason states the disease mechanism — it motivates the therapy rather than explaining the delivery method. The therapy's defining feature (gene delivery into cells) is not explained by the enzyme deficiency itself.",
     "Medium", None),

    # ---------------- Biology: Plant physiology extras ----------------
    ("Biology", "Mineral Nutrition", 11, "Biological nitrogen fixation",
     "Nitrogen fixation cannot occur in the presence of oxygen.",
     "Leghaemoglobin in root nodules acts as an oxygen scavenger.",
     "B",
     "Both statements are true: nitrogenase is oxygen-sensitive, and leghaemoglobin buffers free O2 in the nodule. But leghaemoglobin is the plant's PROTECTION against the sensitivity — it does not explain why the enzyme is oxygen-sensitive; that lies in nitrogenase's own chemistry.",
     "Medium", None),

    ("Biology", "Plant Growth and Development", 11, "Abscission",
     "Auxin produced by young leaves and fruits delays their abscission.",
     "Auxin maintains the tissue's sensitivity balance so the abscission layer does not form prematurely.",
     "A",
     "The auxin gradient across the abscission zone keeps the zone insensitive to ethylene while auxin supply lasts; when supply falls, the abscission layer forms. Hormonal control of the abscission layer is the mechanism.",
     "Hard", None),

    ("Biology", "Transport in Plants", 11, "Transpiration",
     "Transpiration is called a necessary evil.",
     "It creates the tension that pulls water up the plant but costs the plant substantial water loss.",
     "A",
     "The tension from evaporation drives the ascent of sap (essential) while most absorbed water is simply lost through stomata (costly). The benefit-and-cost pairing in the reason is exactly why the phrase 'necessary evil' is used.",
     "Easy", None),

    # ---------------- Chemistry: Electrochemistry ----------------
    ("Chemistry", "Electrochemistry", 12, "Conductance",
     "Molar conductivity of a weak electrolyte increases sharply on dilution.",
     "The degree of dissociation of a weak electrolyte increases as concentration decreases.",
     "A",
     "Weak electrolytes are partially ionised; dilution shifts the dissociation equilibrium toward more ions (Ostwald's dilution law). Molar conductivity rises because more ions per mole are now conducting. The degree-of-dissociation effect IS the explanation.",
     "Medium", None),

    ("Chemistry", "Electrochemistry", 12, "Conductance",
     "Conductivity (specific conductance) of a solution decreases on dilution.",
     "The number of ions per unit volume decreases on dilution even though molar conductivity rises.",
     "A",
     "Conductivity counts ions in a fixed volume; dilution spreads the same ions through more volume, so kappa falls. Molar conductivity (kappa × 1000/M) can still rise due to increased dissociation. The ion-density drop explains the fall in kappa.",
     "Medium", None),

    ("Chemistry", "Electrochemistry", 12, "Electrolysis",
     "Fluorine cannot be prepared by electrolysis of aqueous hydrogen fluoride.",
     "In aqueous solution, water is oxidised at the anode in preference to fluoride ion.",
     "A",
     "F- is an extremely weak reducing agent; at the anode, water/OH- discharges first, giving O2 instead of F2. That is why industrial fluorine uses molten KF·2HF. The preferential water oxidation explains why the aqueous route fails.",
     "Hard", None),

    ("Chemistry", "Electrochemistry", 12, "Batteries",
     "During recharging, a lead storage battery operates as an electrolytic cell.",
     "An external voltage drives the cell reaction in reverse, making it non-spontaneous.",
     "A",
     "Charging forces electrons backward through the cell, regenerating Pb and PbO2 from PbSO4 — an electrolytic process by definition (non-spontaneous reaction driven by external emf). The reason states exactly what defines electrolytic operation.",
     "Medium", None),

    ("Chemistry", "Electrochemistry", 12, "Galvanic cells",
     "A galvanic cell converts chemical energy into electrical work.",
     "The spontaneous redox reaction pushes electrons through the external circuit from anode to cathode.",
     "A",
     "Spontaneity (negative delta-G) means the redox reaction can deliver electrical work as electrons flow through the wire. The electron flow described in the reason is the physical form of that conversion.",
     "Easy", None),

    ("Chemistry", "Electrochemistry", 12, "Corrosion",
     "Salting of roads in winter accelerates the rusting of car bodies.",
     "Dissolved salts increase the conductivity of the aqueous electrolyte on the metal surface.",
     "A",
     "Rusting is electrochemical: it needs an electrolyte to close the circuit between anodic and cathodic patches. Salt raises ionic conductivity, speeding the corrosion current — the reason is the mechanism.",
     "Medium", None),

    # ---------------- Chemistry: Kinetics ----------------
    ("Chemistry", "Chemical Kinetics", 12, "First-order reactions",
     "For a first-order reaction, the time for 99% completion is about twice the time for 90% completion.",
     "In a first-order reaction, equal fractions of the remaining reactant decompose in equal times, regardless of the starting concentration.",
     "A",
     "First-order kinetics is fractional per unit time: 10-fold reduction is one 'decade'; 90% completion is 1 decade (t = 2.303/k), 99% is 2 decades (t = 4.606/k). The constant-fraction behaviour in the reason is why the times double.",
     "Hard", None),

    ("Chemistry", "Chemical Kinetics", 12, "Order of reaction",
     "The order of a reaction can be fractional.",
     "Order is an experimental quantity derived from the rate law, not from the stoichiometric coefficients.",
     "A",
     "Complex mechanisms give rate laws with fractional exponents (e.g., CHCl3 + Cl2, order 1.5). Because order is read off the experimental rate expression rather than the balanced equation, fractions are possible — the reason explains the assertion.",
     "Medium", None),

    ("Chemistry", "Chemical Kinetics", 12, "Zero-order reactions",
     "For a zero-order reaction, reactant concentration falls linearly with time.",
     "The rate of a zero-order reaction is constant and independent of the reactant's concentration.",
     "A",
     "[A] = [A]0 - kt for zero order: constant slope because rate = k. The concentration-independence in the reason is what produces the straight-line decline.",
     "Medium", None),

    ("Chemistry", "Chemical Kinetics", 12, "Catalysis",
     "A catalyst increases the equilibrium constant of a reversible reaction.",
     "A catalyst lowers the activation energy by providing an alternative pathway.",
     "C",
     "The reason is true, but the assertion is false: a catalyst speeds BOTH forward and reverse reactions equally, so equilibrium is reached faster but its constant (and position) is unchanged — only kinetics, not thermodynamics, is affected.",
     "Easy", None),

    ("Chemistry", "Chemical Kinetics", 12, "Rate of reaction",
     "The rate of a reaction generally decreases as it proceeds.",
     "Rate depends on reactant concentration, which falls as reactants are consumed.",
     "A",
     "For positive orders, rate = k[A]^x... with [A] declining over time, the measured rate declines too. The concentration dependence in the reason is the direct cause.",
     "Easy", None),

    ("Chemistry", "Chemical Kinetics", 12, "Temperature dependence",
     "The rate of most reactions approximately doubles for a 10-degree rise in temperature.",
     "A modest temperature rise sharply increases the fraction of molecules crossing the activation-energy barrier.",
     "A",
     "The Boltzmann distribution puts significantly more molecules above Ea at higher T; the exponential Arrhenius factor turns that into a roughly doubled rate. The barrier-crossing population is the mechanism.",
     "Medium", None),

    # ---------------- Chemistry: Solutions / Colligative ----------------
    ("Chemistry", "Solutions", 12, "Raoult and Henry laws",
     "Raoult's law can be regarded as a special case of Henry's law.",
     "Both laws state a proportionality between a gas's partial pressure (or vapour pressure) and its concentration in the phase it contacts.",
     "A",
     "NCERT makes this point explicitly: Henry's law p = K_H·x becomes Raoult's law p = p°·x when the proportionality constant equals the pure-liquid vapour pressure (the infinitely dilute ideal). The shared proportionality form is why one is a special case of the other.",
     "Hard", None),

    ("Chemistry", "Solutions", 12, "Ideal solutions",
     "Benzene and toluene form an almost ideal solution.",
     "Their molecules are structurally similar and have similar intermolecular interactions.",
     "A",
     "Ideality requires A-B interactions to match A-A and B-B; benzene and toluene differ only by a methyl group, so enthalpy of mixing is nearly zero and volume change nil. The molecular similarity is exactly the condition for ideality.",
     "Easy", None),

    ("Chemistry", "Solutions", 12, "Azeotropes",
     "Azeotropic mixtures cannot be separated by simple fractional distillation.",
     "An azeotrope boils at a constant temperature without any change in composition of the vapour.",
     "A",
     "Distillation exploits composition differences between liquid and vapour. For an azeotrope the vapour has the SAME composition as the liquid, so no separation occurs — the constant-composition boiling in the reason is why distillation fails.",
     "Medium", None),

    ("Chemistry", "Solutions", 12, "Colligative properties",
     "Osmotic pressure is the preferred colligative method for finding the molar mass of polymers.",
     "Osmotic-pressure magnitudes remain measurable at very low concentrations where the other colligative effects become too small to determine reliably.",
     "A",
     "Freezing-point depression and boiling-point elevation are tiny for high-molar-mass solutes at low concentration; osmotic pressure of even dilute polymer solutions is large enough to measure precisely. The magnitude advantage explains the preference.",
     "Hard", None),

    ("Chemistry", "Solutions", 12, "Colligative properties",
     "Elevation of boiling point depends on the number of solute particles dissolved, not on their chemical identity.",
     "Elevation of boiling point is classified as a colligative property.",
     "B",
     "Both statements are true, but the reason merely names the classification — it does not explain WHY the property is particle-count-based. That explanation lies in entropy/vapour-pressure lowering being proportional to solute particle mole fraction, which is not what the reason says.",
     "Medium", None),

    # ---------------- Chemistry: Coordination Compounds ----------------
    ("Chemistry", "Coordination Compounds", 12, "Bonding and magnetism",
     "[Ni(CN)4]2- is diamagnetic whereas [NiCl4]2- is paramagnetic.",
     "CN- is a strong-field ligand that forces electron pairing, while Cl- is a weak-field ligand.",
     "A",
     "Ni2+ is d8. With CN-, dsp2 square-planar pairing gives no unpaired electrons; with Cl-, sp3 tetrahedral retains two unpaired electrons. Ligand field strength is exactly what changes the magnetic behaviour.",
     "Medium", None),

    ("Chemistry", "Coordination Compounds", 12, "Coordination number",
     "The coordination number of cobalt in [Co(NH3)4Cl2]+ is six.",
     "Four neutral ammine and two anionic chlorido monodentate ligands are directly bonded to the cobalt centre.",
     "A",
     "Coordination number counts donor atoms bonded to the metal; each NH3 and each Cl- contributes one, so 4 + 2 = 6. The reason enumerates the bonded donor atoms — the very definition.",
     "Easy", None),

    ("Chemistry", "Coordination Compounds", 12, "Crystal field theory",
     "[Fe(CN)6]3- is a low-spin complex.",
     "Fe3+ is d5 and CN- is a strong-field ligand whose splitting energy exceeds the pairing energy.",
     "A",
     "Low spin results when the ligand-field splitting beats pairing energy, forcing electrons to pair in t2g. d5 Fe3+ with CN- gives t2g5 (one unpaired electron). The reason states the energy condition that produces the low-spin configuration.",
     "Medium", None),

    ("Chemistry", "Coordination Compounds", 12, "Isomerism",
     "Tetrahedral complexes rarely show geometrical isomerism.",
     "In a tetrahedron all four coordination positions are mutually adjacent.",
     "A",
     "Cis/trans isomerism needs two kinds of positions (adjacent vs opposite). A tetrahedron has no trans position — every ligand is cis to every other — so MA2B2-type complexes cannot show geometrical isomerism. The uniform adjacency is the cause.",
     "Hard", None),

    ("Chemistry", "Coordination Compounds", 12, "Ligands",
     "EDTA4- is a hexadentate ligand.",
     "It donates two nitrogen and four oxygen donor atoms to a single metal centre.",
     "A",
     "Two amine nitrogens + four carboxylate oxygens = six donor atoms binding one metal — the definition of hexadentate, which makes EDTA complexes (e.g., [Ca(EDTA)]2-) highly stable. The reason enumerates the donors.",
     "Medium", None),

    ("Chemistry", "Coordination Compounds", 12, "Isomerism",
     "Linkage isomerism requires an ambidentate ligand.",
     "NO2- can coordinate to a metal through nitrogen (nitro) or through oxygen (nitrito).",
     "A",
     "Linkage isomerism is the alternative binding mode of one ligand; that requires two different donor atoms in the same ligand — ambidentate. NO2- (N-bound vs O-bound) is the textbook case, so the reason explains the requirement.",
     "Medium", None),

    ("Chemistry", "Coordination Compounds", 12, "Applications",
     "EDTA is used to treat lead poisoning.",
     "EDTA chelates heavy-metal ions into stable, water-soluble complexes that the body can excrete.",
     "A",
     "Chelation therapy works because the multidentate ligand wraps the toxic metal (Pb2+) into a soluble complex cleared by the kidneys. The chelation chemistry in the reason is the therapeutic mechanism.",
     "Easy", None),

    # ---------------- Physics ----------------
    ("Physics", "Current Electricity", 12, "Electrical measuring instruments",
     "An ideal voltmeter has infinite resistance.",
     "A voltmeter is connected in parallel and must draw negligible current to measure the true potential difference.",
     "A",
     "A parallel instrument with finite resistance acts as a shunt path, altering the very circuit it measures. Infinite (or very high) resistance makes its current draw negligible — the reason is why the assertion is the design goal.",
     "Easy", None),

    ("Physics", "Current Electricity", 12, "Electrical measuring instruments",
     "An ideal ammeter has zero resistance.",
     "An ammeter is connected in series and must not lower the current it is measuring.",
     "A",
     "A series instrument adds its own resistance to the circuit; zero resistance means the measured current is unchanged. The reason is the purpose behind the ideal value.",
     "Easy", None),

    ("Physics", "Current Electricity", 12, "Drift velocity",
     "Doubling the current in a conductor doubles the electron drift speed.",
     "I = n e A v_d, and n and A are constants for a given conductor.",
     "A",
     "With charge-carrier density and cross-section fixed, current is proportional to drift velocity — I ∝ v_d. The constitutive equation in the reason is the direct basis.",
     "Medium", None),

    ("Physics", "Electric Charges and Fields", 12, "Conductors",
     "The electric field inside a charged hollow conducting shell is zero.",
     "In electrostatic equilibrium, excess charge resides on the outer surface, and any interior cavity field would drive currents until it vanishes.",
     "A",
     "Free electrons redistribute until the interior field is zero; charge on the outer surface with no enclosed field is the equilibrium configuration. The reason describes the physics that forces the zero field.",
     "Medium", None),

    ("Physics", "Gravitation", 11, "Escape speed",
     "The escape speed from the surface of a planet is independent of the direction of projection.",
     "Escape speed depends only on the planet's mass and radius through v = sqrt(2GM/R).",
     "A",
     "Energy conservation gives 1/2 mv^2 - GMm/R = 0 regardless of launch angle (neglecting atmosphere/rotation). The formula in the reason contains no angular term, which is why direction does not matter.",
     "Medium", None),

    ("Physics", "Nuclei", 12, "Nuclear structure",
     "Nuclear density is approximately the same for all nuclei.",
     "Nuclear mass and nuclear volume both grow in proportion to the mass number A.",
     "A",
     "Density = mass/volume = (A × m_nucleon)/(4/3 pi R0^3 A) — the A cancels because R = R0 A^(1/3). Both statements' proportionality to A is exactly why the ratio is constant.",
     "Hard", None),

    ("Physics", "Magnetism and Matter", 12, "Galvanometer conversion",
     "A moving-coil galvanometer is converted into an ammeter by connecting a small resistance in parallel.",
     "The shunt carries most of the current, leaving a small, proportional fraction through the galvanometer coil.",
     "A",
     "Ammeters need a low-resistance path; the shunt (small S) diverts current so coil current is a fixed fraction I·S/(S+G) — linearly readable. The shunt's working in the reason explains the conversion.",
     "Medium", None),

    # ---------------- balanced-verdict entries (B / C / D) ----------------
    ("Biology", "Cell: The Unit of Life", 11, "Cell organelles",
     "The mitochondrion is called the powerhouse of the cell.",
     "Mitochondria are absent in prokaryotic cells.",
     "B",
     "Both statements are true: mitochondria generate most cellular ATP, and prokaryotes lack them. But prokaryotic absence does not EXPLAIN the powerhouse label — that comes from the organelle's oxidative phosphorylation machinery. The reason is an unrelated true fact.",
     "Medium", None),

    ("Biology", "Human Health and Disease", 12, "Immunity",
     "Vaccination provides active immunity.",
     "Vaccines contain dead or weakened pathogens or their products that stimulate the recipient's immune system.",
     "A",
     "Active immunity means the body's OWN immune system mounts the response; the antigenic stimulus in a vaccine is exactly what triggers that clonal expansion and memory formation. The reason is the working mechanism of the assertion.",
     "Medium", None),

    ("Chemistry", "Surface Chemistry", 12, "Colloids",
     "A colloid is a homogeneous mixture.",
     "Colloidal particles scatter a beam of light, producing the Tyndall effect.",
     "C",
     "The assertion is false: a colloid is HETEROGENEOUS — dispersed-phase particles (1-1000 nm) form a distinct phase within the dispersion medium. The reason is true (Tyndall scattering arises from colloidal-size particles), but scattering is itself evidence of heterogeneity, not homogeneity.",
     "Medium", None),

    ("Chemistry", "Haloalkanes and Haloarenes", 12, "Reactivity",
     "Iodoalkanes are more reactive than chloroalkanes toward nucleophilic substitution.",
     "The C-I bond has lower bond dissociation energy than the C-Cl bond because iodine is larger, making the bond longer and weaker.",
     "A",
     "Bond-dissociation energies: C-I (about 234 kJ/mol) is far weaker than C-Cl (about 350 kJ/mol), so iodide leaves more easily in both SN1 and SN2 pathways. The bond-strength difference in the reason IS the chemical cause of the reactivity order.",
     "Medium", None),

    ("Physics", "Motion in a Plane", 11, "Circular motion",
     "A body moving with uniform speed along a circle is accelerating.",
     "The body's velocity vector changes direction continuously even though its magnitude is constant.",
     "A",
     "Acceleration is the time-derivative of the VELOCITY vector; a changing direction is a changing vector, so centripetal acceleration (v²/r, directed toward the centre) exists. The reason states exactly the vector change that produces the acceleration.",
     "Medium", None),

    ("Biology", "Ecosystem", 12, "Ecological pyramids",
     "The pyramid of energy is always upright.",
     "Only about 10 percent of the energy reaching one trophic level is transferred to the next.",
     "A",
     "Energy shrinks at every transfer (heat lost in respiration), so each higher level holds less energy than the one below — no inversion is possible even when biomass pyramids invert. The 10-percent transfer rule is the arithmetic cause of the constant upright shape.",
     "Medium", None),

    ("Physics", "Gravitation", 11, "Satellites",
     "A geostationary satellite orbits Earth with a period of 24 hours.",
     "The satellite must orbit in the equatorial plane at a specific height so that it appears stationary relative to the ground.",
     "B",
     "Both statements are true — the period is 24 hours (sidereal day), and the equatorial plane plus specific altitude (about 36,000 km) are the requirements for apparent stationarity. But the reason lists ADDITIONAL stationarity conditions; it does not explain why the period is 24 hours (that follows from Kepler's third law applied to that radius).",
     "Hard", None),
]


def build() -> list[dict]:
    return [_ar(*e) for e in ENTRIES]


# ---------------------------------------------------------------------------
# Selftest
# ---------------------------------------------------------------------------
def _selftest() -> None:
    verdicts = {"A": 0, "B": 0, "C": 0, "D": 0}
    stems = set()
    for e in ENTRIES:
        (subject, chapter, ncert_class, topic, assertion, reason, verdict,
         expl, diff, pyq) = e
        assert verdict in verdicts, f"bad verdict {verdict}: {assertion[:40]}"
        assert len(assertion) > 25 and len(reason) > 25, f"thin A/R: {assertion[:40]}"
        assert assertion.strip().lower() != reason.strip().lower()
        assert len(expl) > 80, f"thin explanation: {assertion[:40]}"
        assert diff in ("Easy", "Medium", "Hard")
        assert ncert_class in (11, 12)
        assert pyq is None or (isinstance(pyq, list) and all(2000 <= y <= 2026 for y in pyq))
        verdicts[verdict] += 1
        stems.add(assertion)
    assert len(stems) == len(ENTRIES), "duplicate assertions"
    q = build()[0]
    assert q["options"] == AR_OPTIONS
    print(f"assertion_reason selftest: {len(ENTRIES)} entries OK, verdict mix {verdicts}")


if __name__ == "__main__":
    _selftest()
