#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_835.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

old = """  const evaluated = sorted.map((item) => {
    const evaluation = evaluateCampaign(item, {
      threshold: 8,
      level: "premium",
      campaign: true,
    });

    return {
      ...item,
      evaluation,
      dedupeKey: campaignKey(item),
    };
  });
"""

new = """  const evaluated = sorted.map((item) => {
    const evaluation = evaluateCampaign(item, {
      threshold: Number(currentAutoPipelineThreshold || 2),
      level: "premium",
      campaign: true,
    });

    return {
      ...item,
      evaluation,
      dedupeKey: campaignKey(item),
    };
  });
"""

if old not in text:
    raise SystemExit("❌ Fant ikke blokken med threshold: 8")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Byttet hardkodet threshold 8 til currentAutoPipelineThreshold")
PY

echo
grep -n "threshold:" "$FILE" | sed -n '1,120p'
echo
node --check "$FILE"
echo "✅ 835 ferdig"
