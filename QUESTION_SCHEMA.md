# CodeRank — Question Data Schema

Every question in the bank must follow this exact structure. Two audiences: whoever is tagging/sourcing questions (use the field spec and example), and Claude Code implementing the Dart model (use the code section at the bottom).

---

## Field-by-field spec

| Field | Required? | Type | Description | Example |
|---|---|---|---|---|
| `id` | Yes | string | Unique ID, keep existing prefix convention | `"PHY-0142"` |
| `subject` | Yes | string | Physics, Chemistry, or Biology | `"Biology"` |
| `chapter` | Yes | string | Exact NCERT chapter name (Class 11 or 12) | `"Human Reproduction"` |
| `ncert_class` | Yes | int | 11 or 12 | `12` |
| `topic` | Yes | string | Sub-topic within the chapter | `"Spermatogenesis"` |
| `difficulty` | Yes | string | Easy, Medium, or Hard | `"Medium"` |
| `bloom_level` | Yes | string | recall, application, or analysis — see guide below | `"application"` |
| `question_text` | Yes | string | The question itself | — |
| `options` | Yes | array of 4 strings | The four answer choices | — |
| `correct_option` | Yes | string | A, B, C, or D | `"B"` |
| `explanation` | Yes | string | Full teacher-style explanation — not just "B is correct" | — |
| `common_wrong_reasoning` | Recommended | object | Per wrong option: one sentence on the likely misconception | see example below |
| `neet_pyq_year` | Optional | int array | Years this concept appeared in a real NEET paper | `[2021, 2019]` |
| `avg_time_seconds` | Optional | int | Expected answer time. Defaults: Easy 45s, Medium 75s, Hard 110s | `75` |
| `diagram` | Optional | string | Filename in assets/practice/diagrams/ if needed | `"BIO-D07.png"` |

### bloom_level guide
- **recall** — straight factual retrieval. "What is the powerhouse of the cell?"
- **application** — applying a concept to a new scenario. "A cell has X condition — what happens to ATP production?"
- **analysis** — multi-step reasoning or interpretation. "Given this graph, which conclusion is correct?"

### common_wrong_reasoning format
```json
"common_wrong_reasoning": {
  "A": "confuses mitosis with meiosis — picks this if they think chromosome number stays the same",
  "C": "mixes up the stage order — thinks this happens before prophase I",
  "D": "correct process, wrong cell type — describes oogenesis instead of spermatogenesis"
}
```
Only include entries for wrong options where there's a real, nameable misconception. Don't force entries that aren't genuine.

---

## Full example question

```json
{
  "id": "BIO-1042",
  "subject": "Biology",
  "chapter": "Human Reproduction",
  "ncert_class": 12,
  "topic": "Spermatogenesis",
  "difficulty": "Medium",
  "bloom_level": "application",
  "question_text": "During spermatogenesis, a primary spermatocyte undergoes meiosis I to form which of the following?",
  "options": [
    "Two secondary spermatocytes",
    "Four spermatids directly",
    "One secondary spermatocyte and one polar body",
    "Two spermatogonia"
  ],
  "correct_option": "A",
  "explanation": "Meiosis I is a reductional division — the primary spermatocyte (diploid, 2n) divides to form two secondary spermatocytes, each haploid (n). This is distinct from oogenesis, where meiosis I produces one secondary oocyte and one polar body due to unequal cytoplasm division.",
  "common_wrong_reasoning": {
    "B": "skips a step — assumes meiosis I directly produces the final haploid spermatids",
    "C": "confuses spermatogenesis with oogenesis, where polar bodies are produced",
    "D": "confuses meiosis with earlier mitotic proliferation of spermatogonia"
  },
  "neet_pyq_year": [2021],
  "avg_time_seconds": 75,
  "diagram": null
}
```

---

## Dart model for Claude Code — question_model.dart

```dart
class Question {
  final String id;
  final String subject;
  final String chapter;
  final int ncertClass;
  final String topic;
  final String difficulty;
  final String bloomLevel;
  final String questionText;
  final List<String> options;
  final String correctOption;
  final String explanation;
  final Map<String, String>? commonWrongReasoning;
  final List<int>? neetPyqYear;
  final int avgTimeSeconds;
  final String? diagram;

  Question({
    required this.id,
    required this.subject,
    required this.chapter,
    required this.ncertClass,
    required this.topic,
    required this.difficulty,
    required this.bloomLevel,
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.explanation,
    this.commonWrongReasoning,
    this.neetPyqYear,
    this.avgTimeSeconds = 75,
    this.diagram,
  });

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'],
        subject: json['subject'],
        chapter: json['chapter'],
        ncertClass: json['ncert_class'],
        topic: json['topic'],
        difficulty: json['difficulty'],
        bloomLevel: json['bloom_level'],
        questionText: json['question_text'],
        options: List<String>.from(json['options']),
        correctOption: json['correct_option'],
        explanation: json['explanation'],
        commonWrongReasoning: json['common_wrong_reasoning'] != null
            ? Map<String, String>.from(json['common_wrong_reasoning'])
            : null,
        neetPyqYear: json['neet_pyq_year'] != null
            ? List<int>.from(json['neet_pyq_year'])
            : null,
        avgTimeSeconds: json['avg_time_seconds'] ?? 75,
        diagram: json['diagram'],
      );
}
```

---

## Migration note for existing 2,500 questions

The existing bank has `subject` and `difficulty` already. Everything else (`chapter`, `topic`, `bloom_level`, `explanation` upgrades, `common_wrong_reasoning`) needs to be added per question. This is tagging work — filling in new fields on existing questions, not rewriting the questions themselves. Explanations that already exist in decent form can be upgraded rather than replaced.
