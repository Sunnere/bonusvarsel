#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
cp "$FILE" "$FILE.bak_813.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

original = text

text = text.replace(
    "finalNotifyA =",
    "const finalNotifyA ="
)

text = text.replace(
    "finalNotifyB =",
    "const finalNotifyB ="
)

text = text.replace(
    "finalMultiplierA =",
    "const finalMultiplierA ="
)

text = text.replace(
    "finalMultiplierB =",
    "const finalMultiplierB ="
)

text = text.replace(
    "finalScoreA =",
    "const finalScoreA ="
)

text = text.replace(
    "finalScoreB =",
    "const finalScoreB ="
)

if text == original:
    raise SystemExit("❌ Fant ikke feilene – stopp")

p.write_text(text)
print("✅ Fikset ReferenceError i sort()")
PY

node --check "$FILE"
echo "✅ Syntax OK"

echo "👉 Restart API nå"
