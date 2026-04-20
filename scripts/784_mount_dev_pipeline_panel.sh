#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_784.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

if "_devPipelinePanel()" in text:
    print("ℹ️ DevPipelinePanel allerede mountet – hopper over")
    exit(0)

anchor = """_queueActionsCard(),
          const SizedBox(height: 16),
          _alertSimulationCard(),"""

replacement = """_queueActionsCard(),
          const SizedBox(height: 16),

          _devPipelinePanel(),

          const SizedBox(height: 16),
          _alertSimulationCard(),"""

if anchor not in text:
    raise SystemExit("❌ Fant ikke riktig anchor for å mounte DevPipelinePanel")

text = text.replace(anchor, replacement, 1)
p.write_text(text)

print("✅ DevPipelinePanel mountet i Dev Hub")
PY

flutter analyze
echo "✅ 784 ferdig"
