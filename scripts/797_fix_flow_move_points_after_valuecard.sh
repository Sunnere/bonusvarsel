#!/usr/bin/env bash
set -euo pipefail

echo "==> 797_fix_flow_move_points_after_valuecard"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_797")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

# Finn Din poengstatus blokk
pattern = re.compile(
    r"Container\([\s\S]*?Din poengstatus[\s\S]*?\),\n\s*const SizedBox\(height: 14\),",
    re.MULTILINE,
)

match = pattern.search(text)
if not match:
    print("❌ Fant ikke Din poengstatus-blokken")
    raise SystemExit(1)

points_block = match.group(0)

# Fjern den fra original plass
text = text.replace(points_block, "")

# Sett den inn etter TravelValueCard
anchor = """TravelValueCard(
                amountNok: amount,
                selectedProgram: _selectedProgram,
              ),"""

if anchor not in text:
    print("❌ Fant ikke TravelValueCard anchor")
    raise SystemExit(1)

text = text.replace(
    anchor,
    anchor + "\n              const SizedBox(height: 14),\n" + points_block,
    1,
)

path.write_text(text)
print("✅ Flyttet Din poengstatus til riktig plass")
PY

echo
echo "Kjør:"
echo "  flutter analyze"
echo "  flutter run -d macos"
