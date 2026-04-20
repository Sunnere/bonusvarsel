#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_822.$(date +%s)"
echo "✅ Backup laget: $FILE"

echo
echo "=== Treffer før endring ==="
grep -n "_expandedHistoryRows" "$FILE" || {
  echo "❌ Fant ikke _expandedHistoryRows"
  exit 1
}

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
lines = p.read_text().splitlines()

matches = [i for i, line in enumerate(lines) if "_expandedHistoryRows" in line]
if len(matches) != 1:
    raise SystemExit(f"❌ Forventet nøyaktig 1 treff på _expandedHistoryRows, fant {len(matches)}")

idx = matches[0]
removed = lines.pop(idx)
p.write_text("\n".join(lines) + "\n")

print("✅ Fjernet linje:")
print(removed)
PY

echo
flutter analyze
echo "✅ 822 ferdig"
