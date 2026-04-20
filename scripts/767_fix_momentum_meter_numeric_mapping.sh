#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/bonusvarsel_dev_hub_page.dart")
text = p.read_text()

old = "                value: (evaluation['momentum']?.toString()) ?? 0,"
new = """                value: (() {
                  final raw = evaluation['momentum']?.toString().toLowerCase() ?? '';
                  if (raw == 'high') return 3;
                  if (raw == 'medium') return 2;
                  if (raw == 'low') return 1;
                  return 0;
                })(),"""

if old not in text:
    raise SystemExit("❌ Fant ikke forventet momentum value-linje")

text = text.replace(old, new, 1)
p.write_text(text)
print("✅ Momentum meter mapper nå tekst til tall")
PY

flutter analyze
echo "✅ 767 ferdig"
