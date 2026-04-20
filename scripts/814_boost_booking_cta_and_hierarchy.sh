#!/usr/bin/env bash
set -euo pipefail

echo "==> 814_boost_booking_cta_and_hierarchy"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_814")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# 1. Gjør headline mer beslutningsbasert
text = text.replace(
    "Book flyreisen til",
    "Beste valg: Book flyreisen til",
    1
)

# 2. Legg inn confidence line
text = text.replace(
    "flowBody =",
    "flowBody = 'Basert på valgene dine:\\n' +",
    1
)

# 3. Gjør CTA enda tydeligere
text = text.replace(
    "primaryCta = 'Start booking med SAS →';",
    "primaryCta = '🔥 Start booking med SAS nå';",
    1
)

# 4. Gjør sekundær CTA svakere (riktig hierarki)
text = text.replace(
    "secondaryCta = 'Sammenlign SkyTeam';",
    "secondaryCta = 'Se alternativer';",
    1
)

if text == orig:
    print("❌ Ingen endringer ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 814 ferdig – CTA og hierarchy forbedret")
PY

echo
echo "Kjør:"
echo "  flutter run -d macos"
