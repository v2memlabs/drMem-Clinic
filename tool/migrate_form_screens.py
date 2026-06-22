#!/usr/bin/env python3
"""Migrate standard form screens to ClinicalFormScaffold."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib" / "features"

SKIP = {
    "clinical_encounter_form_screen.dart",
    "maintenance_tenant_form_screen.dart",
    "post_op_protocol_form_screen.dart",
    "anamnesis_form_screen.dart",
    "examination_form_screen.dart",
    "diagnosis_form_screen.dart",
    "treatment_plan_form_screen.dart",
}

OPEN_PATTERN = re.compile(
    r"return AppShell\(\s*"
    r"title:\s*(?P<title>(?:'[^']*'|\"[^\"]*\")),\s*"
    r"child:\s*Column\(\s*"
    r"children:\s*\[\s*"
    r"Expanded\(\s*"
    r"child:\s*LayoutBuilder\(\s*"
    r"builder:\s*\(context,\s*constraints\)\s*\{\s*"
    r"final\s+width\s*=\s*FormScreenLayout\.contentWidth\([^)]*\);\s*"
    r"return\s+Align\(\s*"
    r"alignment:\s*Alignment\.topCenter,\s*"
    r"child:\s*SizedBox\(\s*"
    r"width:\s*width,\s*"
    r"child:\s*ListView\(\s*"
    r"padding:\s*FormScreenLayout\.scrollPadding\(\),\s*"
    r"children:\s*\[",
    re.DOTALL,
)

CLOSE_PATTERN = re.compile(
    r"\],\s*\),\s*\),\s*\),\s*\);\s*\},\s*\),\s*\),\s*"
    r"FormScreenLayout\.bottomActions\(\s*"
    r"onSave:\s*(?P<save>[^,]+),\s*"
    r"onCancel:\s*(?P<cancel>[^,]+),\s*"
    r"saveLabel:\s*(?P<label>[^,\)]+)(?:,\s*saving:\s*(?P<saving>[^,\)]+))?\s*,?\s*\),\s*"
    r"\],\s*\),\s*\);\s*$",
    re.DOTALL,
)


def depth_prefix(path: Path) -> str:
    rel = path.relative_to(ROOT)
    depth = len(rel.parts) - 1
    return "../" * (depth + 2)


def ensure_imports(text: str, prefix: str) -> str:
    form_imp = f"import '{prefix}shared/widgets/clinical_form_scaffold.dart';\n"
    stacked_imp = f"import '{prefix}shared/widgets/clinical_stacked_sections.dart';\n"
    spacing_imp = f"import '{prefix}core/theme/app_spacing.dart';\n"
    shell_imp = f"import '{prefix}shared/widgets/app_shell.dart';\n"

    if form_imp not in text:
        text = text.replace(shell_imp, shell_imp + form_imp + stacked_imp, 1)
    if "app_spacing.dart" not in text and "AppSpacing" not in text:
        pass
    elif f"import '{prefix}core/theme/app_spacing.dart'" not in text:
        # insert after first import block line if AppSpacing needed later
        if "AppSpacing.lg" in text and spacing_imp not in text:
            first = text.find("import '")
            end = text.find("\n", first) + 1
            text = text[:end] + spacing_imp + text[end:]
    return text


def migrate(path: Path) -> bool:
    if path.name in SKIP:
        return False
    text = path.read_text(encoding="utf-8")
    if "ClinicalFormScaffold" in text:
        return False

    m_open = OPEN_PATTERN.search(text)
    if not m_open:
        return False

    m_close = CLOSE_PATTERN.search(text[m_open.end() :])
    if not m_close:
        return False

    children = text[m_open.end() : m_open.end() + m_close.start()].strip()
    title = m_open.group("title")
    save = m_close.group("save").strip()
    cancel = m_close.group("cancel").strip()
    label = m_close.group("label").strip()
    saving = m_close.group("saving")
    saving_line = f",\n      saving: {saving.strip()}" if saving else ""

    prefix = depth_prefix(path)
    text = ensure_imports(text, prefix)

    # Split PageHeader from form sections when possible
    header = ""
    sections = children
    header_m = re.match(
        r"(const\s+PageHeader\([^;]+\),)\s*(.*)",
        children,
        re.DOTALL,
    )
    if header_m:
        header = header_m.group(1) + "\n              "
        sections = header_m.group(2).strip()

    new_build_tail = f"""return ClinicalFormScaffold(
      shellTitle: {title},
      onSave: {save},
      onCancel: {cancel},
      saveLabel: {label}{saving_line},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          {header}ClinicalStackedSections(
            children: [
              {sections}
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }}
}}"""

    # Replace from return AppShell to end of build method
    build_start = text.rfind("Widget build(BuildContext context)", 0, m_open.start())
    if build_start < 0:
        return False
    brace = text.find("{", build_start)
    # find last closing of build method - use close match end
    end = m_open.start() + m_close.end()
    # include closing brace of build
    end = text.find("}", end) + 1

    new_text = text[: m_open.start()] + new_build_tail + text[end:]
    path.write_text(new_text, encoding="utf-8")
    return True


def main() -> None:
    count = 0
    for path in sorted(ROOT.rglob("*_form_screen.dart")):
        try:
            if migrate(path):
                print(f"migrated {path.relative_to(ROOT.parent.parent)}")
                count += 1
        except Exception as exc:
            print(f"error {path.name}: {exc}")
    print(f"done: {count} files")


if __name__ == "__main__":
    main()
