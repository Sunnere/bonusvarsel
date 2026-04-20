#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_834.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("api/server.js")
text = p.read_text()
original = text

# Bytt bare auto-pipeline-kallet til å sende ren threshold direkte.
patterns = [
"""      const evaluation = evaluateCampaign(item, {
      threshold: currentAutoPipelineThreshold,
      level: "premium",
      campaign: true,
    });""",
"""      const evaluation = evaluateCampaign(item, {
        threshold: currentAutoPipelineThreshold,
        level: "premium",
        campaign: true,
      });""",
]

replacement = """      const evaluation = evaluateCampaign(item, {
      threshold: Number(currentAutoPipelineThreshold || 2),
      alertThreshold: null,
      level: "premium",
      campaign: true,
    });"""

changed = False
for pat in patterns:
    if pat in text:
        text = text.replace(pat, replacement, 1)
        changed = True
        break

if not changed:
    raise SystemExit("❌ Fant ikke auto-pipeline evaluateCampaign-blokken")

p.write_text(text)
print("✅ Auto-pipeline sender nå eksplisitt threshold=global og ignorerer bruker-prefs")
PY

echo
grep -n "evaluateCampaign(item" -A6 "$FILE" | sed -n '1,40p'
echo
node --check "$FILE"
echo "✅ node --check OK"
