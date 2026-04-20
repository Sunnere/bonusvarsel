#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_788.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

# Fjern evt eksisterende feilplasserte mounts
text = text.replace("_devPipelinePanel(),", "")

# Finn riktig sted etter queueActions
pattern = r"_queueActionsCard\(\),\s*\n\s*const SizedBox\(height: 16\),"

replacement = """_queueActionsCard(),
          const SizedBox(height: 16),

          _devPipelinePanel(),

          const SizedBox(height: 16),"""

if not re.search(pattern, text):
    raise SystemExit("❌ Fant ikke korrekt plassering etter _queueActionsCard")

text = re.sub(pattern, replacement, text, count=1)

p.write_text(text)
print("✅ Pipeline panel tvunget inn etter queue actions")
PY

flutter analyze
echo "✅ 788 ferdig"
