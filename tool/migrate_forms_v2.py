#!/usr/bin/env python3
"""Migrate AppShell+LayoutBuilder forms to ClinicalFormScaffold."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "features"

SKIP = {
    "clinical_encounter_form_screen.dart",
    "clinical_report_form_screen.dart",
    "maintenance_tenant_form_screen.dart",
}

BLOCK = re.compile(
    r"return AppShell\(\s*"
    r"title:\s*(?P<title>[^,]+),\s*"
    r"child:\s*Column\(\s*"
    r"children:\s*\[\s*"
    r"Expanded\(\s*"
    r"child:\s*LayoutBuilder\(\s*"
    r"builder:\s*\(context,\s*constraints\)\s*\{\s*"
    r"final\s+width\s*=\s*FormScreenLayout\.contentWidth\(\s*"
    r"constraints\.maxWidth(?:,\s*longForm:\s*(?:true|false))?\s*\);\s*"
    r"return\s+Align\(\s*"
    r"alignment:\s*Alignment\.topCenter,\s*"
    r"child:\s*SizedBox\(\s*"
    r"width:\s*width,\s*"
    r"child:\s*(?P<formwrap>Form\(\s*key:\s*(?P<formkey>[^,]+),\s*child:\s*)?"
    r"ListView\(\s*"
    r"padding:\s*FormScreenLayout\.scrollPadding\(\),\s*"
    r"children:\s*\[(?P<body>.*?)\]\s*,\s*\)\s*,?"
    r"(?:\)\s*,)?\s*\)\s*,\s*\)\s*;\s*"
    r"\}\s*,\s*\)\s*,\s*\)\s*,\s*"
    r"FormScreenLayout\.bottomActions\(\s*"
    r"onSave:\s*(?P<save>[^,]+),\s*"
    r"onCancel:\s*(?P<cancel>[^,]+),\s*"
    r"saveLabel:\s*(?P<label>[^,\)]+)"
    r"(?:,\s*saving:\s*(?P<saving>[^,\)]+))?"
    r"\s*,?\s*\)\s*,\s*"
    r"\]\s*,\s*\)\s*,\s*\)\s*;",
    re.DOTALL,
)

LIST_ALIGNED = re.compile(
    r"return AppShell\(\s*"
    r"title:\s*(?P<title>[^,]+),\s*"
    r"child:\s*Column\(\s*"
    r"children:\s*\[\s*"
    r"Expanded\(\s*"
    r"child:\s*FormScreenLayout\.listAlignedScroll\(\s*"
    r"header:\s*(?P<header>const\s+PageHeader\([\s\S]*?\),)\s*,\s*"
    r"sections:\s*\[(?P<sections>[\s\S]*?)\]\s*,\s*\)\s*,\s*\)\s*,\s*"
    r"FormScreenLayout\.bottomActions\(\s*"
    r"onSave:\s*(?P<save>[^,]+),\s*"
    r"onCancel:\s*(?P<cancel>[^,]+),\s*"
    r"saveLabel:\s*(?P<label>[^,\)]+)"
    r"(?:,\s*saving:\s*(?P<saving>[^,\)]+))?"
    r"\s*,?\s*\)\s*,\s*"
    r"\]\s*,\s*\)\s*,\s*\)\s*;",
    re.DOTALL,
)


def depth_prefix(path: Path) -> str:
    rel = path.relative_to(ROOT)
    return "../" * (len(rel.parts) - 1 + 2)


def ensure_import(text: str, prefix: str) -> str:
    imp = f"import '{prefix}shared/widgets/clinical_form_scaffold.dart';\n"
    if imp in text:
        return text
    shell = f"import '{prefix}shared/widgets/app_shell.dart';\n"
    if shell in text:
        return text.replace(shell, shell + imp, 1)
    return imp + text


def split_header_sections(body: str):
    body = body.strip()
    m = re.match(
        r"(?P<header>PageHeader\([\s\S]*?\),)\s*(?P<rest>[\s\S]*)",
        body,
    )
    if not m:
        return None, body
    return m.group("header"), m.group("rest").strip()


def migrate_layout_builder(text: str, path: Path) -> str:
    m = BLOCK.search(text)
    if not m:
        return text
    prefix = depth_prefix(path)
    text = ensure_import(text, prefix)

    header, sections = split_header_sections(m.group("body"))
    if not header:
        return text

    formkey_line = ""
    if m.group("formkey"):
        formkey_line = f"\n      formKey: {m.group('formkey').strip()},"

    saving_line = ""
    if m.group("saving"):
        saving_line = f"\n      saving: {m.group('saving').strip()},"

    replacement = f"""return ClinicalFormScaffold.sections(
      shellTitle: {m.group('title').strip()},
      onSave: {m.group('save').strip()},
      onCancel: {m.group('cancel').strip()},
      saveLabel: {m.group('label').strip()},{saving_line}{formkey_line}
      header: {header},
      sections: [
{sections}
      ],
    );"""

    return text[: m.start()] + replacement + text[m.end() :]


def migrate_list_aligned(text: str, path: Path) -> str:
    m = LIST_ALIGNED.search(text)
    if not m:
        return text
    prefix = depth_prefix(path)
    text = ensure_import(text, prefix)

    saving_line = ""
    if m.group("saving"):
        saving_line = f"\n      saving: {m.group('saving').strip()},"

    replacement = f"""return ClinicalFormScaffold.sections(
      shellTitle: {m.group('title').strip()},
      onSave: {m.group('save').strip()},
      onCancel: {m.group('cancel').strip()},
      saveLabel: {m.group('label').strip()},{saving_line}
      header: {m.group('header').strip()},
      sections: [
{m.group('sections').strip()}
      ],
    );"""

    return text[: m.start()] + replacement + text[m.end() :]


def main() -> None:
    n = 0
    for path in sorted(ROOT.rglob("*_form_screen.dart")):
        if path.name in SKIP:
            continue
        original = path.read_text(encoding="utf-8")
        text = migrate_layout_builder(original, path)
        text = migrate_list_aligned(text, path)
        if text != original:
            path.write_text(text, encoding="utf-8")
            print("migrated", path.relative_to(ROOT.parent.parent))
            n += 1
    print("total", n)


if __name__ == "__main__":
    main()
