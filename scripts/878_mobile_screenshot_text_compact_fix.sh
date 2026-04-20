#!/usr/bin/env bash
set -euo pipefail

PREMIUM="lib/pages/premium_page.dart"
SHOP="lib/pages/eb_shopping_page.dart"

[[ -f "$PREMIUM" ]] || { echo "❌ Fant ikke $PREMIUM"; exit 1; }
[[ -f "$SHOP" ]] || { echo "❌ Fant ikke $SHOP"; exit 1; }

cp "$PREMIUM" "$PREMIUM.bak_878.$(date +%s)"
cp "$SHOP" "$SHOP.bak_878.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path

files = [
    Path("lib/pages/premium_page.dart"),
    Path("lib/pages/eb_shopping_page.dart"),
]

replacements = [
    ("Mest valgt • Best for de fleste", "Mest valgt"),
    ("Mest verdi", "Best verdi"),
    ("Typisk ekstra: +2 000–8 000 poeng/år", "Typisk ekstra: +2k–8k poeng/år"),
    ("Typisk ekstra: +2 000-8 000 poeng/år", "Typisk ekstra: +2k–8k poeng/år"),
    ("Fortsett gratis", "Gratis"),
    ("Start Premium", "Premium"),
    ("Oppgrader", "Oppgrader"),
    ("Boost-tilbud og kampanjer", "Boost og kampanjer"),
    ("Maks oversikt i appen", "Maks oversikt"),
    ("Ingen boost / høyeste rate", "Ingen boost / topp-rate"),
    ("Begrenset antall butikker", "Begrensede butikker"),
    ("Gratis vs Premium", "Gratis vs Premium"),
    ("Favoritter først", "Favoritter"),
    ("Kun kampanjer", "Kampanjer"),
    ("Sorter: høy rate", "Sortér: høy rate"),
    ("Boost – Oppgrader for å se poengrate", "Boost – oppgrader"),
    ("Boost - Oppgrader for å se poengrate", "Boost – oppgrader"),
    ("Boost – Oppgrader for å se poengrate", "Boost – oppgrader"),
    ("Standard", "Basis"),
]

changed = 0
for p in files:
    text = p.read_text()
    original = text
    for old, new in replacements:
        if old in text:
            text = text.replace(old, new)
    if text != original:
        p.write_text(text)
        changed += 1
        print(f"✅ Oppdatert {p}")
    else:
        print(f"ℹ️ Ingen tekstendringer i {p}")

if changed == 0:
    raise SystemExit("❌ Ingen endringer ble gjort")
PY

flutter analyze
echo "✅ 878 ferdig"
