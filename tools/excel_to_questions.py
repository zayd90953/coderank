import json
import re
from pathlib import Path

import openpyxl


# --------------------------------------------------
# FILE PATHS
# --------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
EXCEL_FILE = BASE_DIR / "question_bank.xlsx"
OUTPUT_FILE = BASE_DIR / "questions.json"


# --------------------------------------------------
# HELPERS
# --------------------------------------------------

def clean(value):
    if value is None:
        return ""
    return str(value).strip()


def answer_to_index(answer):
    answer = clean(answer).upper()

    mapping = {
        "A": 0,
        "B": 1,
        "C": 2,
        "D": 3,
    }

    if answer not in mapping:
        raise ValueError(f"Invalid answer: {answer}")

    return mapping[answer]


def extract_diagram_id(question_text):
    """
    Finds diagram references such as:

    [PHY-D01]
    [See diagram PHY-D25]
    [CHEM-D05]
    [BIO-D12]
    """

    match = re.search(
        r"\b([A-Z]+-D\d+)\b",
        question_text,
        re.IGNORECASE,
    )

    if match:
        return match.group(1).upper()

    return None


# --------------------------------------------------
# LOAD WORKBOOK
# --------------------------------------------------

print("Loading workbook...")

workbook = openpyxl.load_workbook(
    EXCEL_FILE,
    read_only=True,
    data_only=True,
)

sheet = workbook["All 2500 MCQs"]


# --------------------------------------------------
# READ HEADERS
# --------------------------------------------------

rows = sheet.iter_rows(values_only=True)

headers = [clean(value) for value in next(rows)]

header_index = {
    header: index
    for index, header in enumerate(headers)
}


required_columns = [
    "ID",
    "Subject",
    "Branch",
    "Chapter",
    "Core Concept",
    "Question Type",
    "Difficulty",
    "Question",
    "Option A",
    "Option B",
    "Option C",
    "Option D",
    "Answer",
    "Explanation",
    "Source/Pattern",
]


for column in required_columns:
    if column not in header_index:
        raise ValueError(
            f"Missing required column: {column}"
        )


# --------------------------------------------------
# CONVERT QUESTIONS
# --------------------------------------------------

questions = []

for row_number, row in enumerate(rows, start=2):

    if not row:
        continue

    question_text = clean(
        row[header_index["Question"]]
    )

    if not question_text:
        continue

    diagram_id = extract_diagram_id(
        question_text
    )

    question = {
        "id": clean(row[header_index["ID"]]),

        "subject": clean(
            row[header_index["Subject"]]
        ),

        "branch": clean(
            row[header_index["Branch"]]
        ),

        "chapter": clean(
            row[header_index["Chapter"]]
        ),

        "coreConcept": clean(
            row[header_index["Core Concept"]]
        ),

        "questionType": clean(
            row[header_index["Question Type"]]
        ),

        "difficulty": clean(
            row[header_index["Difficulty"]]
        ),

        "question": question_text,

        "options": [
            clean(row[header_index["Option A"]]),
            clean(row[header_index["Option B"]]),
            clean(row[header_index["Option C"]]),
            clean(row[header_index["Option D"]]),
        ],

        "correctAnswer": answer_to_index(
            row[header_index["Answer"]]
        ),

        "explanation": clean(
            row[header_index["Explanation"]]
        ),

        "sourcePattern": clean(
            row[header_index["Source/Pattern"]]
        ),

        "diagramId": diagram_id,
    }

    questions.append(question)


# --------------------------------------------------
# SAVE JSON
# --------------------------------------------------

print(f"Questions processed: {len(questions)}")

with open(
    OUTPUT_FILE,
    "w",
    encoding="utf-8",
) as file:

    json.dump(
        questions,
        file,
        ensure_ascii=False,
        indent=2,
    )


# --------------------------------------------------
# SUMMARY
# --------------------------------------------------

subject_counts = {}

diagram_count = 0

for question in questions:

    subject = question["subject"]

    subject_counts[subject] = (
        subject_counts.get(subject, 0) + 1
    )

    if question["diagramId"]:
        diagram_count += 1


print()
print("================================")
print("IMPORT COMPLETE")
print("================================")
print(f"Total questions: {len(questions)}")

for subject, count in subject_counts.items():
    print(f"{subject}: {count}")

print(f"Diagram questions: {diagram_count}")
print(f"Output: {OUTPUT_FILE}")
print("================================")