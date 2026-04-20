#!/usr/bin/env bash
set -euo pipefail

echo "==> 806_fix_reiseprofil_dropdown_popup_tone_safe"

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
bak = path.with_name(path.name + f".bak_{stamp}_806")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

old = """                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reiseprofil',
"""

new = """                child: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: const Color(0xFFF3F8F9),
                    splashColor: Colors.transparent,
                    highlightColor: const Color(0x140F3A4A),
                    hoverColor: const Color(0x100F3A4A),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'Reiseprofil',
"""

if old not in text:
    print("❌ Fant ikke Reiseprofil-blokken for trygg patch")
    print("Kjør og send:")
    print("  sed -n '870,965p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old, new, 1)

old_end = """                  ],
                ),
              ),
"""

new_end = """                  ],
                  ),
                ),
              ),
"""

if old_end not in text:
    print("❌ Fant ikke slutten av Reiseprofil-blokken")
    print("Kjør og send:")
    print("  sed -n '965,1035p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old_end, new_end, 1)

if text == orig:
    print("❌ Ingen endring ble gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 806 ferdig: popup i Reiseprofil får mykere premium-tone")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
