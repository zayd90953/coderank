# App-integration note — if demo questions replace the main bank

**TL;DR: A schema-format bank (the `QUESTION_SCHEMA.md` JSON) is NOT drop-in
compatible with the current app. The app expects a different JSON shape
(`question_model.dart`), so a conversion step is required before replacing
`lib/features/practice/data/questions.json`. No code changes are strictly
required if you convert the data; a few optional upgrades become possible.**

---

## 1. What the app currently expects

`QuestionModel.fromJson` (`lib/features/practice/models/question_model.dart`)
parses exactly these keys, and throws if any is missing:

| App key | Type | Notes |
|---|---|---|
| `id` | String | e.g. `NEET-0001` |
| `subject` | String | `Physics` / `Chemistry` / `Biology` |
| `branch` | String | `Mixed`, `Core`, `Physical`, `Organic`, `Inorganic`, `Botany`, `Zoology`, `Mechanics`, `Electrodynamics`, … |
| `chapter` | String | |
| `coreConcept` | String | |
| `questionType` | String | one of: `Numerical`, `Concept check`, `Diagram-based`, `Core concept`, `Correct match`, `Direct concept`, `Application` |
| `difficulty` | String | `Easy` / `Medium` / `Hard` |
| `question` | String | (schema calls it `question_text`) |
| `options` | List<String> | |
| `correctAnswer` | **int** (0-based index) | (schema uses `correct_option` letter A–D) |
| `explanation` | String | |
| `sourcePattern` | String | |
| `diagramId` | String? | nullable |
| `timeLimitSeconds` | int, default 60 | **never present in current bank** — the `?? 60` fallback fires everywhere |

Everything except `diagramId` is **required and non-null** — a missing key or a
string where an int is expected makes the whole app crash on load, because the
repository parses the entire file up front.

## 2. Field-by-field mapping (schema → app)

| QUESTION_SCHEMA.md | question_model.dart | Conversion needed |
|---|---|---|
| `id` | `id` | none |
| `subject` | `subject` | none (same values) |
| — | `branch` | **must be derived** (see mapping below) |
| `chapter` | `chapter` | none |
| `topic` | `coreConcept` | rename (this actually improves the app's data quality — the current bank has filler values like `"Core calculation"`, `"Energy flow"` duplicated as concept and chapter) |
| `bloom_level` | `questionType` | **approximate mapping** (see below) |
| `difficulty` | `difficulty` | none (same values) |
| `question_text` | `question` | rename |
| `options` | `options` | none |
| `correct_option` ("A"–"D") | `correctAnswer` (0–3) | `letterToIndex = {'A':0,'B':1,'C':2,'D':3}` |
| `explanation` | `explanation` | none — the schema explanations are far richer |
| `common_wrong_reasoning` | **no field exists** | app cannot show per-option misconceptions unless `QuestionModel` is extended (optional, see §4) |
| `neet_pyq_year` | **no field exists** | optional extension (see §4) |
| `avg_time_seconds` | `timeLimitSeconds` | direct rename; unlike the current bank, our values are actually populated |
| `diagram` | `diagramId` | rename; `null` maps to `null` safely. 220 questions now carry a real SVG filename — the files live in `demo_set_qns/diagrams/` and must be bundled as assets (see §6) |
| `type` | — (new field) | `mcq` / `assertion_reason` / `statement_match`; default `mcq` when absent. The current app model has no such field — optional extension (see §6) |
| — | `sourcePattern` | **must be synthesized** (see below) |

Suggested derivations:

- `branch` (subject → allowed values in current bank):
  - Physics by `chapter`: Electrostatics/Current Electricity/Moving Charges/EMI/EM Waves → `Electrodynamics`; Ray Optics/Wave Optics → `Optics`; Thermodynamics → `Thermodynamics`; Kinetic Theory → `Kinetic Theory`; Oscillations → `Oscillations`; Waves → `Waves`; Units, Laws of Motion, Work-Energy, Gravitation, Properties of Matter, Rotational, Fluids → `Mechanics`; Atoms, Nuclei, Dual Nature, Semiconductors → `Modern Physics` (current bank uses `Semiconductors` as a separate branch for that chapter); anything mixed/unclear → `Mixed`
  - Chemistry: `chapter` in Organic set (Hydrocarbons, Haloalkanes, Alcohols, Aldehydes/Ketones, Amines, Biomolecules, Polymers, Chemistry in Everyday Life) → `Organic`; Inorganic set (p-Block, d- and f-Block, Coordination Compounds, Periodicity, Metallurgy) → `Inorganic`; everything else → `Physical`
  - Biology: NCERT Class 11 zoology-leaning physiology chapters (Digestion, Breathing, Body Fluids, Excretory, Locomotion, Neural, Chemical Coordination) + Human Reproduction + Evolution → `Zoology`; the rest → `Botany` (this mirrors how the current 988-question zoology/botany split behaves)

- `questionType` from schema fields:
  - `bloom_level == "recall"` → `Direct concept`
  - `bloom_level == "application"` and explanation contains "=" or a numeric setup → `Numerical`
  - otherwise → `Application` (and `Concept check` for non-numerical application)
  - (All six existing `questionType` values are treated as opaque strings by the
    model; nothing in the app filters on them, so any string works. But keep to
    the existing vocabulary for analytics consistency.)

- `sourcePattern`: use an honest string such as
  `"Authentic NEET PYQ (year N); adapted wording"` or
  `"PYQ-pattern inspired; original wording"` — this matches the existing bank's
  convention.

## 3. What happens on drop-in replacement WITHOUT conversion

Replacing `questions.json` with schema-format JSON and nothing else:
1. `QuestionModel.fromJson` throws on the first question (missing `branch`,
   `coreConcept`, `questionType`, `sourcePattern`; `correctAnswer` is a string).
2. Every screen that loads the bank — Practice, Mock Test, Daily Challenge —
   crashes at load time.
3. There is **no caching issue** to worry about: `QuestionRepository` caches the
   parsed list in memory per session, so a new file is picked up on next app
   start with zero code changes.

## 4. Optional code changes worth making when migrating

These are *not required* for the swap, but the new data supports them and they
would improve the app:

1. **Per-option misconception feedback**: extend `QuestionModel` with
   `final Map<String, String>? commonWrongReasoning;` (fromJson: `json['common_wrong_reasoning'] != null ? Map<String,String>.from(json['common_wrong_reasoning']) : null`) and surface it on the results/review screen when the student picks a wrong option. This is the single highest-value upgrade — the schema data already contains genuinely diagnostic one-liners per wrong option.
2. **PYQ badge**: add `final List<int>? neetPyqYear;` and show "Asked in NEET 2019" on questions that have it. Boosts student trust.
3. **Use `timeLimitSeconds`**: the field is parsed but never read by the practice/mock screens (they use their own global timers). With populated per-question times, per-question timers become possible.
4. **Filter by `coreConcept`/`topic`**: the new data has real topic values, enabling topic-wise practice lists.

## 5. Recommended path (least risk)

1. Keep both files: current bank stays; schema-format questions live in
   `demo_set_qns/` (already the case).
2. Write a one-shot conversion script (`demo_set_qns/convert_to_app_format.py`)
   that applies the §2 mapping and emits an app-format JSON file.
3. Validate the converted output with a small Dart test or a Python check that
   asserts every required `QuestionModel.fromJson` key exists with the right type.
4. Decide merge policy: the new batch occupies `NEET-15000+` and cannot collide
   with the existing bank (`NEET-0001…2500` originals + the absorbed
   `NEET-9060…14041` block). Appending is zero-risk; replacing should wait for
   a subject-expert review of the new questions.

## 6. New formats — what the app needs to render them

### 6a. Diagram questions (220, all formats `mcq` + non-null `diagram`)

- **Dependency**: add `flutter_svg` to `pubspec.yaml` (pure-Dart SVG renderer;
  no native build steps).
- **Assets**: declare the folder in `pubspec.yaml`:
  ```yaml
  flutter:
    assets:
      - assets/practice/diagrams/
  ```
  and copy `demo_set_qns/diagrams/*.svg` there (filenames already match the
  `diagram`/`diagramId` field: `D0001.svg` …). The schema's original convention
  was PNG in `assets/practice/diagrams/`; these are `.svg` — keep the extension
  consistent between the field value and the bundled files.
- **Rendering**: `SvgPicture.asset('assets/practice/diagrams/${q.diagramId}')`
  below the question text. The SVGs carry their own white rounded card, so they
  work on both light and dark backgrounds without tinting.
- **Fallback**: if `diagramId` is set but the file is missing, show a "figure
  unavailable" box rather than crashing — treat missing assets as a soft error.

### 6b. Assertion–Reason (79, `type: "assertion_reason"`)

- The stem already contains `Assertion (A): … / Reason (R): …` as plain text —
  rendering it as-is in the existing question widget works, but splitting the
  lines (split on `\n`) and styling the labels bold reads much better.
- Options are always the canonical four-NEET-AR set in the same order; no
  shuffling logic is needed or wanted.

### 6c. Statement-match (35, `type: "statement_match"`)

- Stem contains `Statement I/II/III:` lines plus the standard "which … is/are
  correct?" closer; options are combination strings ("I and II only", etc.).
- Same rendering approach: keep the line breaks. No model changes needed —
  everything fits the existing `question`/`options` shape.

### 6d. Optional model extension for formats

Add to `QuestionModel`: `final String type;` with
`type: json['type'] ?? 'mcq'`. This lets the UI branch on format (e.g. show the
figure card only for diagram questions, use the AR layout). Not required for
correctness — a plain MCQ widget renders all formats, just less nicely.

### 6e. Conversion-script notes for the new formats

The §2 mapping needs these extra rules:
- `questionType`: map `type == "assertion_reason"` → `"Correct match"` (or add
  your own value — the model treats it as an opaque string); diagram questions
  → `"Diagram-based"` (the value already exists in the app's vocabulary but is
  never used by the current bank).
- `diagramId`: pass through the `.svg` filename; make sure the assets folder
  registration (§6a) happens in the same release, or null these out instead.
- AR/statement-match stems contain `\n` characters — they are plain strings in
  JSON and survive conversion unchanged.
