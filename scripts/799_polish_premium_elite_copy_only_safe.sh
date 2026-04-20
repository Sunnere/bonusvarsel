#!/usr/bin/env bash
set -euo pipefail

echo "==> 799_polish_premium_elite_copy_only_safe"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_799")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

replacements = [
    (
        "Premium gir raskere vei videre til riktig fly-, hotell- eller leiebilflyt.",
        "Premium gir bedre forslag, raskere vei videre og tydeligere verdi i valg av fly, hotell og leiebil.",
    ),
    (
        "Premium: bedre flyforslag og poengverdi aktivert",
        "Premium: bedre forslag og sterkere poengverdi aktivert",
    ),
    (
        "Premium aktiv",
        "Premium aktiv • bedre forslag",
    ),
    (
        "Se butikker",
        "Se beste tilbud",
    ),
    (
        "Best for Fly",
        "Mest relevant nå",
    ),
    (
        "Bruk poeng på fly til Bangkok",
        "Bruk poeng smart på fly til Bangkok",
    ),
    (
        "Butikker som passer før flyreisen",
        "Butikker som passer best før flyreisen",
    ),
    (
        "Fokus på bagasje, elektronikk og praktiske kjøp som gir verdi før avreise.",
        "Utvalgte kategorier med høy relevans før avreise, bedre poengfangst og smartere kjøp før flyreisen.",
    ),
    (
        "Bra for flyreise når familien trenger mer plass, bedre pakking og smartere organisering.",
        "Sterk kategori før flyreise når familien trenger mer plass, smartere pakking og høy nytte før avreise.",
    ),
    (
        "Powerbank, adapter, hodetelefoner og ladere gir høy nytte før avreise.",
        "Powerbank, adapter, hodetelefoner og ladere er typiske kjøp som gir høy nytte og ofte god poengverdi før avreise.",
    ),
    (
        "Solkrem, hygiene, reiseapotek og småting som ofte glemmes til flyturen.",
        "Solkrem, hygiene, reiseapotek og småting som ofte glemmes, men som er smarte å samle i ett bonuskjøp før avreise.",
    ),
]

changed = 0
for old, new in replacements:
    if old in text:
        text = text.replace(old, new)
        changed += 1

if text == orig:
    print("❌ Ingen eksakte teksttreff funnet")
    print("Kjør dette og send resultatet:")
    print("  sed -n '180,280p' lib/pages/travel_page.dart")
    print("  sed -n '620,720p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 799 ferdig, {changed} tekstendringer brukt")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
