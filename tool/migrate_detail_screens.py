#!/usr/bin/env python3
"""Bulk detail screen cleanup for Post-op reference layout."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "features"

REPLACEMENTS = [
    (re.compile(r"import '[^']*detail_scroll_cue\.dart';\n"), ""),
    (re.compile(r"\s*const DetailScrollCue\(\),\n"), "\n"),
    (re.compile(r"\n\s*compact: true,"), ""),
    (re.compile(r"ResponsiveSectionColumns\("), "ClinicalStackedSections("),
]

IMPORT_STACKED = "import '../../shared/widgets/clinical_stacked_sections.dart';\n"
IMPORT_STACKED_DEEP = "import '../../../shared/widgets/clinical_stacked_sections.dart';\n"


def depth_import(path: Path) -> str:
    rel = path.relative_to(ROOT)
    depth = len(rel.parts) - 1
    prefix = "../" * (depth + 2)
    return f"import '{prefix}shared/widgets/clinical_stacked_sections.dart';\n"


def main() -> None:
    for path in ROOT.rglob("*_detail_screen.dart"):
        text = path.read_text(encoding="utf-8")
        original = text
        for pattern, repl in REPLACEMENTS:
            text = pattern.sub(repl, text)
        if "ClinicalStackedSections" in text and "clinical_stacked_sections.dart" not in text:
            text = depth_import(path) + text
        if text != original:
            path.write_text(text, encoding="utf-8")
            print(f"updated {path.relative_to(ROOT.parent.parent)}")


if __name__ == "__main__":
    main()
