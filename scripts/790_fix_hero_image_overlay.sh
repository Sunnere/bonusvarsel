#!/usr/bin/env bash
set -euo pipefail

echo "==> 790_fix_hero_image_overlay"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_790")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
orig = text

# 🔧 Finn og erstatt tung overlay gradient
text = re.sub(
    r"Colors\.black\.withOpacity\([0-9.]+\)",
    "Colors.black.withValues(alpha: 0.18)",
    text
)

# 🔧 hvis det finnes flere lag, gjør de enda lettere
text = text.replace("alpha: 0.18", "alpha: 0.12")

if text == orig:
    print("❌ Fant ikke overlay å justere")
    raise SystemExit(1)

path.write_text(text)
print("✅ Hero overlay gjort mye lettere (mer premium)")
PY

echo
echo "Kjør:"
echo "  flutter analyze"
echo "  flutter run -d macos"
