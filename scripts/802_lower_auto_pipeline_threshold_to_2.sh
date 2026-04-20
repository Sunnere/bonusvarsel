#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_802.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()

old1 = """      const evaluation = evaluateCampaign(item, {
      threshold: 8,
      level: "premium",
      campaign: true,
    });"""

new1 = """      const evaluation = evaluateCampaign(item, {
      threshold: 2,
      level: "premium",
      campaign: true,
    });"""

old2 = """  const threshold = Number(reqBody.threshold || 8);"""
new2 = """  const threshold = Number(reqBody.threshold || 2);"""

changed = 0
if old1 in text:
    text = text.replace(old1, new1, 1)
    changed += 1
if old2 in text:
    text = text.replace(old2, new2, 1)
    changed += 1

if changed == 0:
    raise SystemExit("❌ Fant ikke threshold-blokkene å oppdatere")

p.write_text(text)
print(f"✅ Oppdaterte {changed} threshold-blokker til 2")
PY

node --check "$FILE"
echo "✅ 802 ferdig"
