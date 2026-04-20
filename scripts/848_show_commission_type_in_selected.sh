#!/usr/bin/env bash
set -euo pipefail

FILE="lib/widgets/dev_pipeline_panel.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_848.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()
original = text

# Vi legger kun til commissionType chip hvis den ikke allerede er der
old = """_infoChip('Score', score),"""

new = """_infoChip('Score', score),
                        if (commissionType.isNotEmpty && commissionType != '-')
                          _infoChip('Type', commissionType),"""

if old not in text:
    raise SystemExit("❌ Fant ikke Score-chip (feil versjon av fil?)")

text = text.replace(old, new, 1)

if text == original:
    raise SystemExit("❌ Ingen endring gjort")

p.write_text(text)
print("✅ La til commissionType i Selected for dispatch")
PY

flutter analyze
echo "✅ 848 ferdig"
