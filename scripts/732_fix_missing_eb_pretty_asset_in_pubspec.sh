#!/usr/bin/env bash
set -euo pipefail

FILE="pubspec.yaml"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("pubspec.yaml")
text = p.read_text()

needle = "    - assets/eb.shopping.min.json\n"
insert = "    - assets/eb.shopping.min.json\n    - assets/eb.shopping.pretty.json\n"

if "assets/eb.shopping.pretty.json" in text:
    print("✅ assets/eb.shopping.pretty.json finnes allerede i pubspec.yaml")
else:
    if needle not in text:
        raise SystemExit("❌ Fant ikke forventet assets-linje for innsetting")
    text = text.replace(needle, insert, 1)
    p.write_text(text)
    print("✅ La til assets/eb.shopping.pretty.json i pubspec.yaml")
PY

echo "✅ 732 ferdig"
