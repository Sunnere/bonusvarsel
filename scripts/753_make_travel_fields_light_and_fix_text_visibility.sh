#!/usr/bin/env bash
set -euo pipefail

echo "==> 753_make_travel_fields_light_and_fix_text_visibility"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil
import re

path = Path("lib/pages/travel_page.dart")
if not path.exists():
    print("ERROR: Fant ikke lib/pages/travel_page.dart")
    raise SystemExit(1)

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_753")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

text = path.read_text()
original = text

# 1) Gjør alle input/dropdown-felt lysere og labels alltid synlige
text = text.replace(
    "fillColor: Colors.white,",
    "fillColor: const Color(0xFFF4F7FB),",
)

text = text.replace(
    "fillColor: const Color(0xFFF4F7FB),",
    "fillColor: const Color(0xFFF4F7FB),\n"
    "                      floatingLabelBehavior: FloatingLabelBehavior.always,\n"
    "                      alignLabelWithHint: true,",
)

text = text.replace(
    "contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),",
    "contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),",
)

text = text.replace(
    "labelStyle: TextStyle(\n"
    "                        color: Color(0xFF243940),\n"
    "                        fontWeight: FontWeight.w700,\n"
    "                        fontSize: 15,\n"
    "                      ),",
    "labelStyle: const TextStyle(\n"
    "                        color: Color(0xFF23343A),\n"
    "                        fontWeight: FontWeight.w700,\n"
    "                        fontSize: 14,\n"
    "                      ),"
)

text = text.replace(
    "floatingLabelStyle: TextStyle(\n"
    "                        color: Color(0xFF10252B),\n"
    "                        fontWeight: FontWeight.w800,\n"
    "                        fontSize: 16,\n"
    "                      ),",
    "floatingLabelStyle: const TextStyle(\n"
    "                        color: Color(0xFF10252B),\n"
    "                        fontWeight: FontWeight.w800,\n"
    "                        fontSize: 15,\n"
    "                      ),"
)

# 2) Høyere felter
text = text.replace(
    "height: 60,",
    "height: 68,",
)

# 3) Mørkere tekst inne i felt/verdier
text = re.sub(
    r"child: Text\(([^,\n][^)]*?)\)",
    r"child: Text(\1, style: const TextStyle(color: Color(0xFF10252B), fontSize: 18, fontWeight: FontWeight.w800))",
    text,
)

# 4) Poengplan-kort: gjør teksten mørkere og kortet bredere
text = text.replace(
    "color: const Color(0xFFF0E1B8),",
    "color: const Color(0xFFF0E1B8),"
)

text = text.replace(
    "width: double.infinity,",
    "width: double.infinity,",
)

# sikre mørk tekst i poengplan
text = text.replace(
    "color: const Color(0xFF1C3036),",
    "color: const Color(0xFF10252B),",
)

# 5) Hvis poengplan fortsatt har blek tekst, tving viktige linjer mørke
text = text.replace(
    "Text(\n                          'Mulig saldo etter kjøpet:",
    "Text(\n                          'Mulig saldo etter kjøpet:"
)
text = text.replace(
    "Text(\n                          'Manglende poeng til målet:",
    "Text(\n                          'Manglende poeng til målet:"
)

# 6) Gjør hvite/dark cards litt mindre tunge ved å bruke lys kant på feltene
text = text.replace(
    "borderSide: BorderSide.none,",
    "borderSide: const BorderSide(color: Color(0xFFD8E0EA), width: 1),",
)

# 7) Fiks eventuelle dobbeltinnsatte FloatingLabelBehavior
text = text.replace(
    "floatingLabelBehavior: FloatingLabelBehavior.always,\n"
    "                      alignLabelWithHint: true,\n"
    "                      floatingLabelBehavior: FloatingLabelBehavior.always,\n"
    "                      alignLabelWithHint: true,",
    "floatingLabelBehavior: FloatingLabelBehavior.always,\n"
    "                      alignLabelWithHint: true,",
)

if text == original:
    print("No changes made.")
else:
    path.write_text(text)
    print(f"Patched: {path}")
PY

echo
echo "✅ 753 ferdig"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
