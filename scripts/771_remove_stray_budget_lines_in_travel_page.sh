#!/usr/bin/env bash
set -euo pipefail

echo "==> 771_remove_stray_budget_lines_in_travel_page"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("❌ Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_771")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

bad = """height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
"""

if bad not in text:
    print("❌ Fant ikke den løse tekstblokken.")
    print("Kjør dette og send resultatet:")
    print("  sed -n '1288,1320p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(bad, "", 1)

path.write_text(text)
print(f"✅ Fjernet ødelagt blokk i: {path}")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
