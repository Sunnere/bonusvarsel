#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_669_move_membership_section_above_plans_only"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# Finn medlemsseksjonen via dens tydelige overskrift
title_idx = text.find("Start med riktig medlemskap")
if title_idx == -1:
    print("❌ Fant ikke medlemsseksjonen ('Start med riktig medlemskap'). Ingen endring gjort.")
    sys.exit(1)

# Finn starten på blokken: nærmeste 'const SizedBox(height: 14),' før seksjonen
start_idx = text.rfind("                    const SizedBox(height: 14),", 0, title_idx)
if start_idx == -1:
    print("❌ Fant ikke start på medlemsseksjonen. Ingen endring gjort.")
    sys.exit(1)

# Finn slutten på blokken: første 'const SizedBox(height: 18),' etter seksjonen
end_marker = "                    const SizedBox(height: 18),"
end_idx = text.find(end_marker, title_idx)
if end_idx == -1:
    print("❌ Fant ikke slutt på medlemsseksjonen. Ingen endring gjort.")
    sys.exit(1)
end_idx = end_idx + len(end_marker)

membership_block = text[start_idx:end_idx]

# Fjern medlemsseksjonen fra nåværende plassering
text_without = text[:start_idx] + text[end_idx:]

# Sett den inn rett før 'Velg nivå'
insert_marker = """                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: 'Velg nivå',"""

insert_idx = text_without.find(insert_marker)
if insert_idx == -1:
    print("❌ Fant ikke 'Velg nivå'-seksjonen. Ingen endring gjort.")
    sys.exit(1)

new_text = text_without[:insert_idx] + membership_block + "\n\n" + text_without[insert_idx:]

if new_text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(new_text)
print("✅ Flyttet medlemsseksjonen over 'Velg nivå'")
PY

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
