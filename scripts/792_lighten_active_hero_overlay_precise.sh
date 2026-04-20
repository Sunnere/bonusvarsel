#!/usr/bin/env bash
set -euo pipefail

echo "==> 792_lighten_active_hero_overlay_precise"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_792")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

old = """                gradient: const LinearGradient(
                  colors: [
                    Color(0xCC0D1B2A),
                    Color(0x880D1B2A),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
"""

new = """                gradient: const LinearGradient(
                  colors: [
                    Color(0x550D1B2A),
                    Color(0x180D1B2A),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
"""

if old not in text:
    print("❌ Fant ikke eksakt hero-gradient.")
    print("Kjør dette og send resultatet:")
    print("  sed -n '428,448p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old, new, 1)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ Hero-overlay lettet kraftig")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
