#!/usr/bin/env bash
set -euo pipefail

FILE="api/server.js"
cp "$FILE" "$FILE.bak_840.$(date +%s)"

python3 <<'PY'
from pathlib import Path

p = Path("api/server.js")
text = p.read_text()
original = text

old = """      const priorityReason =
        commissionType === 'fixed'
          ? 'fixed commission'
          : multiplier >= autoDispatchMinMultiplier
              ? `multiplier ${multiplier} >= ${autoDispatchMinMultiplier}`
              : score >= autoDispatchMinScore
                  ? `score ${score} >= ${autoDispatchMinScore}`
                  : 'not selected';
"""

new = """      let priorityReason = 'not selected';

      if (commissionType === 'fixed') {
        priorityReason = 'fixed commission';
      } else if (multiplier >= autoDispatchMinMultiplier) {
        priorityReason = `multiplier ${multiplier} >= ${autoDispatchMinMultiplier}`;
      } else if (score >= autoDispatchMinScore) {
        priorityReason = `score ${score} >= ${autoDispatchMinScore}`;
      }
"""

if old not in text:
    raise SystemExit("❌ Fant ikke priorityReason-blokken")

text = text.replace(old, new, 1)

if text == original:
    raise SystemExit("❌ Ingen endring")

p.write_text(text)
print("✅ Fixet priorityReason backend")
PY

node --check "$FILE"
echo "✅ node OK"
