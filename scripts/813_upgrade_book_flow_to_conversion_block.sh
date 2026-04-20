#!/usr/bin/env bash
set -euo pipefail

echo "==> 813_upgrade_book_flow_to_conversion_block"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_813")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# Oppgrader styling i book flow container
text = text.replace(
    "color: const Color(0xFFF2F8F9),",
    "gradient: const LinearGradient("
    "colors: [Color(0xFFE6F4F7), Color(0xFFF8FBFC)],"
    "begin: Alignment.topLeft,"
    "end: Alignment.bottomRight,"
    "),",
)

# Gjør CTA sterkere
text = text.replace(
    "primaryCta = 'Sjekk SAS-fly';",
    "primaryCta = 'Start booking med SAS →';"
)

text = text.replace(
    "secondaryCta = 'Se partnerlogikk';",
    "secondaryCta = 'Sammenlign partnere';"
)

# Gjør partnerlinje mer beslutningsstyrt
text = text.replace(
    "SAS først, deretter relevante partnere hvis tilgjengelighet eller poengbruk er bedre.",
    "👉 Start med SAS. Bytt til partner kun hvis du får bedre poengverdi eller tilgjengelighet."
)

# Litt mer punch i tekst
text = text.replace(
    "Start med fly for",
    "Beste strategi: start med fly for"
)

if text == orig:
    print("❌ Ingen endring gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 813 ferdig – Book flow oppgradert til konverteringsblokk")
PY

echo
echo "Kjør:"
echo "  flutter run -d macos"
