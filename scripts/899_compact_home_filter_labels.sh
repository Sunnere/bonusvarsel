#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_899.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

replacements = [
    ("Sortér: høy rate", "Høy rate"),
    ("Favoritter først", "Favoritter"),
    ("Kun kampanjer", "Kampanjer"),
    ("Gratis vs Premium", "Sammenlign nivåer"),
    ("Finn butikker, kampanjer og poengboost", "Velg nivå og finn det som gir mest poeng"),
]

for old, new in replacements:
    text = text.replace(old, new)

if text == orig:
    raise SystemExit("❌ Ingen filter/tekst-endringer ble gjort")

p.write_text(text)
print("✅ Filtertekster komprimert")
PY

flutter analyze
echo "✅ 899 ferdig"
