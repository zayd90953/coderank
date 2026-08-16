from pathlib import Path
from openpyxl import load_workbook
import zipfile
import re


PROJECT_ROOT = Path(__file__).resolve().parent.parent

WORKBOOK_PATH = PROJECT_ROOT / "tools" / "question_bank.xlsx"
OUTPUT_DIR = PROJECT_ROOT / "assets" / "practice" / "diagrams"


print("Loading workbook...")

workbook = load_workbook(
    WORKBOOK_PATH,
    data_only=True
)

print("Workbook loaded.")

# ============================================================
# 1. Read Diagram Index
# ============================================================

diagram_sheet = workbook["Diagram Index"]

diagram_ids = []

for row in diagram_sheet.iter_rows(
    min_row=2,
    values_only=True
):

    diagram_id = row[0]

    if diagram_id:
        diagram_ids.append(
            str(diagram_id).strip()
        )

print()
print("================================")
print("DIAGRAM INDEX")
print("================================")
print(f"Diagram IDs found: {len(diagram_ids)}")

for diagram_id in diagram_ids[:10]:
    print(diagram_id)

# ============================================================
# 2. Find embedded images inside XLSX
# ============================================================

print()
print("================================")
print("EMBEDDED MEDIA")
print("================================")

with zipfile.ZipFile(
    WORKBOOK_PATH,
    "r"
) as z:

    media_files = sorted(
        [
            name
            for name in z.namelist()
            if name.startswith("xl/media/")
            and name.lower().endswith(
                (".png", ".jpg", ".jpeg", ".webp")
            )
        ],
        key=lambda x: int(
            re.search(
                r"(\d+)",
                Path(x).stem
            ).group(1)
        )
    )

    print(
        f"Embedded images found: "
        f"{len(media_files)}"
    )

    # ========================================================
    # 3. Validate counts
    # ========================================================

    if len(diagram_ids) != len(media_files):

        print()
        print("WARNING!")
        print(
            "Diagram ID count does not match "
            "embedded image count."
        )

        print(
            f"IDs: {len(diagram_ids)}"
        )

        print(
            f"Images: {len(media_files)}"
        )

        raise SystemExit(1)

    # ========================================================
    # 4. Extract and rename
    # ========================================================

    OUTPUT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    print()
    print("================================")
    print("EXTRACTING DIAGRAMS")
    print("================================")

    for index, (
        diagram_id,
        media_file
    ) in enumerate(
        zip(
            diagram_ids,
            media_files
        ),
        start=1
    ):

        extension = Path(
            media_file
        ).suffix

        output_file = (
            OUTPUT_DIR
            / f"{diagram_id}{extension}"
        )

        output_file.write_bytes(
            z.read(media_file)
        )

        print(
            f"[{index}/{len(diagram_ids)}] "
            f"{diagram_id} -> "
            f"{output_file.name}"
        )


print()
print("================================")
print("DIAGRAM EXTRACTION COMPLETE")
print("================================")

print(
    f"Diagrams extracted: "
    f"{len(diagram_ids)}"
)

print(
    f"Output: {OUTPUT_DIR}"
)

print("================================")