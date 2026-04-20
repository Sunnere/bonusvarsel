#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_884.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/premium_page.dart")
text = p.read_text()
orig = text

# Trygg, fokusert justering:
# - gjør Elite mer mørk marine + champagne/gull
# - lar Premium beholde blå profil

repls = [
    ("'Best verdi'", "'Elite valg'"),
    ('"Best verdi"', '"Elite valg"'),
    ("const Color(0xFFD4AF37)", "const Color(0xFFE7C977)"),  # mykere champagne-gull
    ("const Color(0xFF0B1F4D)", "const Color(0xFF0F172A)"),  # mørkere elite-base
]

for old, new in repls:
    text = text.replace(old, new)

# Vanlige elite-labeler/badges
text = text.replace("Elite", "Elite")

# Hvis fila har eksplisitt elite-badge med bakgrunn/border som ligner premium,
# prøv å løfte kontrasten uten å røre store blokker.
text = text.replace(
    "color: const Color(0xFF1E3A8A),",
    "color: const Color(0xFF0F172A),"
)
text = text.replace(
    "border: Border.all(color: const Color(0xFF2F80ED)),",
    "border: Border.all(color: const Color(0xFFE7C977)),"
)

if text == orig:
    raise SystemExit("❌ Ingen Elite-justeringer ble gjort")

p.write_text(text)
print("✅ Justerte Elite til mørkere/luksuriøs profil")
PY

flutter analyze
echo "✅ 884 ferdig"
