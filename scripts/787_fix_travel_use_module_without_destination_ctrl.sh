#!/usr/bin/env bash
set -euo pipefail

echo "==> 787_fix_travel_use_module_without_destination_ctrl"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_787")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

old = """    final destination = _destinationCtrl.text.trim().isEmpty
        ? 'Bangkok'
        : _destinationCtrl.text.trim();
"""

new = """    final destination = 'Bangkok';
"""

if old not in text:
    print("❌ Fant ikke blokken med _destinationCtrl.")
    print("Kjør dette og send resultatet:")
    print("  sed -n '60,90p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old, new, 1)

if text == orig:
    print("❌ Ingen endringer gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ Fjernet avhengighet til _destinationCtrl i reisemål/bruk-modulen")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
