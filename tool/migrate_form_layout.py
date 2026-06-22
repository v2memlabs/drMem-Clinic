#!/usr/bin/env python3
"""Replace narrow form ListView layout with FormScreenLayout.listAlignedScroll."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "features"
SKIP = {
    "clinical_encounter_form_screen.dart",
    "maintenance_tenant_form_screen.dart",
    "post_op_protocol_form_screen.dart",
}

PATTERN = re.compile(
    r"Expanded\(\s*"
    r"child:\s*LayoutBuilder\(\s*"
    r"builder:\s*\(context,\s*constraints\)\s*\{\s*"
    r"final\s+width\s*=\s*FormScreenLayout\.contentWidth\(\s*constraints\.maxWidth(?:,\s*longForm:\s*(?:true|false))?\s*\);\s*"
    r"return\s+Align\(\s*"
    r"alignment:\s*Alignment\.topCenter,\s*"
    r"child:\s*SizedBox\(\s*"
    r"width:\s*width,\s*"
    r"child:\s*ListView\(\s*"
    r"padding:\s*FormScreenLayout\.scrollPadding\(\),\s*"
    r"children:\s*\[(?P<body>.*?)\]\s*,\s*\)\s*,\s*\)\s*,\s*\)\s*;\s*"
    r"\}\s*,\s*\)\s*,\s*\)",
    re.DOTALL,
)


def split_header_and_sections(body: str):
    body = body.strip()
    m = re.match(r"(?P<header>const\s+PageHeader\([\s\S]*?\),)\s*(?P<rest>[\s\S]*)", body)
    if not m:
        return None, body
    return m.group("header"), m.group("rest").strip()


def migrate(path: Path) -> bool:
    if path.name in SKIP:
        return False
    text = path.read_text(encoding="utf-8")
    if "listAlignedScroll" in text or "ClinicalFormScaffold" in text:
        return False
    m = PATTERN.search(text)
    if not m:
        return False

    header, sections = split_header_and_sections(m.group("body"))
    if header:
        replacement = (
            "Expanded(\n"
            "            child: FormScreenLayout.listAlignedScroll(\n"
            f"              header: {header},\n"
            "              sections: [\n"
            f"{sections}\n"
            "              ],\n"
            "            ),\n"
            "          )"
        )
    else:
        replacement = (
            "Expanded(\n"
            "            child: FormScreenLayout.listAlignedScroll(\n"
            "              sections: [\n"
            f"{m.group('body').strip()}\n"
            "              ],\n"
            "            ),\n"
            "          )"
        )

    text = PATTERN.sub(replacement, text, count=1)
    path.write_text(text, encoding="utf-8")
    return True


def main() -> None:
    n = 0
    for path in sorted(ROOT.rglob("*_form_screen.dart")):
        if migrate(path):
            print("migrated", path.relative_to(ROOT.parent.parent))
            n += 1
    print("total", n)


if __name__ == "__main__":
    main()
