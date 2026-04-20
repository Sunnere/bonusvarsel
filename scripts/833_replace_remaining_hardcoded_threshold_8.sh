#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_833.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

target = """      const evaluation = evaluateCampaign(item, {
      threshold: 8,
      level: "premium",
      campaign: true,
    });"""

replacement = """      const evaluation = evaluateCampaign(item, {
      threshold: currentAutoPipelineThreshold,
      level: "premium",
      campaign: true,
    });"""

if target not in text:
    raise SystemExit("❌ Fant ikke den gjenværende hardkodede threshold: 8-blokken")

text = text.replace(target, replacement, 1)

p.write_text(text)
print("✅ Byttet siste hardkodede threshold 8 til currentAutoPipelineThreshold")
PY

echo
grep -n "threshold:" "$FILE" | sed -n '1,120p'
echo
node --check "$FILE"
echo "✅ node --check OK"
