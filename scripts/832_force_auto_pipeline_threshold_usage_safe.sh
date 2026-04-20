#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_832.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("api/server.js")
text = p.read_text()
original = text

# 1) Sørg for at env-threshold finnes
marker = 'let currentAutoPipelineThreshold = Number(process.env.AUTO_PIPELINE_THRESHOLD || 2);\n'
if marker not in text:
    # fallback hvis linjen ikke finnes ennå
    alt = 'const autoPipelineIntervalMs = Number(process.env.AUTO_PIPELINE_INTERVAL_MS || 60000);\n'
    if alt in text and 'AUTO_PIPELINE_THRESHOLD' not in text:
        text = text.replace(
            alt,
            alt + "let currentAutoPipelineThreshold = Number(process.env.AUTO_PIPELINE_THRESHOLD || 2);\n",
            1,
        )

# 2) Bytt hardkodet threshold i evaluateCampaign/request path
text = text.replace(
    "const threshold = Number(reqBody.threshold || 8);",
    "const threshold = Number(reqBody.threshold || reqBody.alertThreshold || prefs?.alertThreshold || currentAutoPipelineThreshold || 2);",
)

text = text.replace(
    "const threshold = Number(reqBody.threshold || 2);",
    "const threshold = Number(reqBody.threshold || reqBody.alertThreshold || prefs?.alertThreshold || currentAutoPipelineThreshold || 2);",
)

# 3) Bytt hardkodet threshold i auto pipeline tick
text = text.replace(
    """      const evaluation = evaluateCampaign(item, {
      threshold: 8,
      level: "premium",
      campaign: true,
    });""",
    """      const evaluation = evaluateCampaign(item, {
      threshold: currentAutoPipelineThreshold,
      level: "premium",
      campaign: true,
    });""",
)

text = text.replace(
    """      const evaluation = evaluateCampaign(item, {
      threshold: 2,
      level: "premium",
      campaign: true,
    });""",
    """      const evaluation = evaluateCampaign(item, {
      threshold: currentAutoPipelineThreshold,
      level: "premium",
      campaign: true,
    });""",
)

# 4) Gjør threshold synlig i health/pipeline hvis feltet finnes
text = text.replace(
    "summary,",
    "summary,\n    threshold: currentAutoPipelineThreshold,",
    1
)

if text == original:
    raise SystemExit("❌ Fant ingen trygg threshold-endring å gjøre i api/server.js")

p.write_text(text)
print("✅ Fikset threshold-bruk i auto pipeline og evaluateCampaign")
PY

echo
node --check "$FILE"
echo "✅ node --check OK"

echo
flutter analyze
echo "✅ 832 ferdig"
