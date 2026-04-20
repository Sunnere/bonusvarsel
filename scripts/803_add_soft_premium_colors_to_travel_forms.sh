#!/usr/bin/env bash
set -euo pipefail

echo "==> 803_add_soft_premium_colors_to_travel_forms"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_803")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

changes = 0

def replace_all(old: str, new: str):
    global text, changes
    count = text.count(old)
    if count:
        text = text.replace(old, new)
        changes += count

# Reiseprofil-kort: myk blågrønn premium
replace_all(
    "color: const Color(0xFFF6FAFC),",
    "color: const Color(0xFFEFF7F8),",
)
replace_all(
    "border: Border.all(color: const Color(0xFFD9E6EA)),",
    "border: Border.all(color: const Color(0xFFD1E4E7)),",
)

# Poengstatus-kort: myk varm premium
replace_all(
    "color: const Color(0xFFF8FBFC),",
    "color: const Color(0xFFFAF6EC),",
)
replace_all(
    "border: Border.all(color: const Color(0xFFDCE7EA)),",
    "border: Border.all(color: const Color(0xFFE8D9B8)),",
)

# Input-felt: vekk fra kritthvitt til myk tint
replace_all(
    "fillColor: const Color(0xFFFFFFFF),",
    "fillColor: const Color(0xFFF9FCFD),",
)

# Litt varmere tint på SAS-poeng-feltet
sas_old = """                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        filled: true,
                        fillColor: const Color(0xFFF9FCFD),
"""
sas_new = """                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        filled: true,
                        fillColor: const Color(0xFFFFFBF3),
"""
if sas_old in text:
    text = text.replace(sas_old, sas_new, 1)
    changes += 1

# Litt mer farge i overskrift-områdene via undertitler
replace_all(
    "color: const Color(0xFF455C64),",
    "color: const Color(0xFF3E5961),",
)
replace_all(
    "color: const Color(0xFF5B7077),",
    "color: const Color(0xFF536C73),",
)

if text == orig or changes == 0:
    print("❌ Ingen sikre fargeendringer ble gjort")
    print("Kjør og send:")
    print("  sed -n '870,1035p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 803 ferdig, {changes} myke premium-fargeendringer brukt")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
