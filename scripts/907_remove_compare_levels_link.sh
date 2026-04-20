#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_907.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

# Fjern InkWell / tekst som inneholder "Sammenlign nivåer"
import re

text = re.sub(
    r"Align\([\s\S]*?Sammenlign nivåer[\s\S]*?\),",
    "",
    text,
    count=1
)

# fallback hvis bare tekst finnes
text = text.replace("'Sammenlign nivåer'", "''")

if text == orig:
    raise SystemExit("❌ Fant ikke 'Sammenlign nivåer' å fjerne")

p.write_text(text)
print("✅ Fjernet 'Sammenlign nivåer'")
PY

flutter analyze
echo "✅ 907 ferdig"
