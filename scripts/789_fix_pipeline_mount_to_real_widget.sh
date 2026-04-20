#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_789.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

if "_devPipelinePanel()" not in text and "DevPipelinePanel()" not in text:
    raise SystemExit("❌ Fant ingen pipeline-mount å rette")

text = text.replace("_devPipelinePanel()", "const DevPipelinePanel()")

import_line = "import '../widgets/dev_pipeline_panel.dart';\n"
if import_line not in text:
    lines = text.splitlines(True)
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith("import "):
            insert_at = i + 1
    lines.insert(insert_at, import_line)
    text = "".join(lines)

p.write_text(text)
print("✅ Byttet til const DevPipelinePanel() og la inn import")
PY

flutter analyze
echo "✅ 789 ferdig"
