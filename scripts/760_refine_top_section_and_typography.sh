#!/usr/bin/env bash
set -euo pipefail

echo "==> 760_refine_top_section_and_typography"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_760")
shutil.copy2(path, bak)

text = path.read_text()
original = text

# 1️⃣ Lysne mørk topp-seksjon (hero container / bakgrunn)
text = text.replace(
    "color: const Color(0xFF10252B)",
    "color: const Color(0xFF0F2A30)"
)

# 2️⃣ Gjør gradient/hero mer subtil (hvis brukt)
text = text.replace(
    "Colors.black.withOpacity(0.6)",
    "Colors.black.withOpacity(0.35)"
)

# 3️⃣ Juster store overskrifter ned litt (2 hakk)
text = text.replace(
    "fontSize: 22",
    "fontSize: 20"
)

text = text.replace(
    "fontSize: 18",
    "fontSize: 16"
)

# 4️⃣ Gjør hero-tekst mer crisp (mindre “bold overload”)
text = text.replace(
    "FontWeight.w900",
    "FontWeight.w800"
)

# 5️⃣ Gjør info-blokk (den mørke med SAS/Trumf) mindre tung
text = text.replace(
    "color: const Color(0xFF10252B)",
    "color: const Color(0xFF0E252A)"
)

# 6️⃣ Øk kontrast på lys tekst i mørk seksjon
text = text.replace(
    "color: Colors.white70",
    "color: Colors.white"
)

if text == original:
    print("No changes made.")
    exit(1)

path.write_text(text)
print("Patched travel_page.dart")
PY

echo
echo "✅ 760 ferdig"
echo
echo "Kjør:"
echo "flutter run -d macos"
