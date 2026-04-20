#!/usr/bin/env bash
set -euo pipefail

echo "==> 813c_upgrade_book_flow_precise_only"

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
bak = path.with_name(path.name + f".bak_{stamp}_813c")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

old_container = """    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E1E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
"""

new_container = """    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE7F4F7),
            Color(0xFFF9FCFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4E1E5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
"""

if old_container not in text:
    print("❌ Fant ikke eksakt container i _buildBangkokBookUseFlow")
    print("Kjør og send:")
    print("  sed -n '340,470p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_container, new_container, 1)

replacements = [
    (
        "primaryCta = 'Sjekk SAS-flyvninger';",
        "primaryCta = 'Start booking med SAS →';",
    ),
    (
        "secondaryCta = 'Se SkyTeam-partnere';",
        "secondaryCta = 'Sammenlign SkyTeam';",
    ),
    (
        "Start med fly for $partyText i $stayText. Vurder direkte eller 1 stopp ut fra poengsaldo, pris og hva som gir best totalverdi.",
        "Beste strategi: start med fly for $partyText i $stayText. Vurder direkte eller 1 stopp ut fra poengsaldo, pris og hva som gir best totalverdi.",
    ),
    (
        "Anbefalt logikk: SAS først, deretter SkyTeam-partnere hvis poeng eller tilgjengelighet er bedre.",
        "Anbefalt logikk: Start med SAS. Bytt til SkyTeam-partner kun hvis tilgjengelighet eller poengverdi er bedre.",
    ),
]

applied = 0
for old, new in replacements:
    if old in text:
        text = text.replace(old, new, 1)
        applied += 1

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 813c ferdig ({applied + 1} presise endringer)")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
