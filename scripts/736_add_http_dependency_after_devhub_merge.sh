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

if "\n  http:" in text:
    print("✅ http finnes allerede i pubspec.yaml")
else:
    needle = "  intl: ^0.19.0\n"
    insert = "  intl: ^0.19.0\n  http: ^1.2.2\n"
    if needle not in text:
        raise SystemExit("❌ Fant ikke forventet plass å legge inn http dependency")
    text = text.replace(needle, insert, 1)
    p.write_text(text)
    print("✅ La til http dependency i pubspec.yaml")
PY

echo "✅ 736 ferdig"
