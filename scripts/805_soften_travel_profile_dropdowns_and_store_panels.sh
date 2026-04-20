#!/usr/bin/env bash
set -euo pipefail

echo "==> 805_soften_travel_profile_dropdowns_and_store_panels"

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
bak = path.with_name(path.name + f".bak_{stamp}_805")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

changes = 0

def replace_all(old: str, new: str):
    global text, changes
    count = text.count(old)
    if count:
        text = text.replace(old, new)
        changes += count

def replace_once(old: str, new: str):
    global text, changes
    if old in text:
        text = text.replace(old, new, 1)
        changes += 1

# ---- 1) Mykere bakgrunn i Reiseprofil/Din poengstatus felter ----
replace_all(
    "fillColor: const Color(0xFFF9FCFD),",
    "fillColor: const Color(0xFFF3F8F9),",
)
replace_all(
    "fillColor: const Color(0xFFFFFBF3),",
    "fillColor: const Color(0xFFFCF7EA),",
)

# litt tydeligere border på feltene
replace_all(
    "border: const OutlineInputBorder(),",
    "border: const OutlineInputBorder(\n"
    "                          borderSide: BorderSide(color: Color(0xFFD4E1E5)),\n"
    "                        ),",
)
replace_all(
    "border: const OutlineInputBorder(),",
    "border: const OutlineInputBorder(\n"
    "                                borderSide: BorderSide(color: Color(0xFFD4E1E5)),\n"
    "                              ),",
)

# ---- 2) Dropdown bakgrunn ikke hvit, men myk tinted ----
replace_all(
    "dropdownColor: Colors.white,",
    "dropdownColor: const Color(0xFFF6FAFB),",
)

# ---- 3) Sørg for mørk tekst også i DropdownMenuItem ----
replace_all(
    "child: Text(t),",
    "child: const TextStyleFixText('@@TMP_T@@'),",
)
replace_all(
    "child: Text('$v'),",
    "child: const TextStyleFixText('@@TMP_V@@'),",
)
replace_all(
    "child: Text('$d dager'),",
    "child: const TextStyleFixText('@@TMP_D@@'),",
)

# Rull tilbake tmp og injiser riktig style basert på value
replace_all(
    "child: const TextStyleFixText('@@TMP_T@@'),",
    "child: Text(\n"
    "                                t,\n"
    "                                style: const TextStyle(\n"
    "                                  color: Color(0xFF162E35),\n"
    "                                  fontWeight: FontWeight.w700,\n"
    "                                ),\n"
    "                              ),",
)
replace_all(
    "child: const TextStyleFixText('@@TMP_V@@'),",
    "child: Text(\n"
    "                                      '$v',\n"
    "                                      style: const TextStyle(\n"
    "                                        color: Color(0xFF162E35),\n"
    "                                        fontWeight: FontWeight.w700,\n"
    "                                      ),\n"
    "                                    ),",
)
replace_all(
    "child: const TextStyleFixText('@@TMP_D@@'),",
    "child: Text(\n"
    "                              '$d dager',\n"
    "                              style: const TextStyle(\n"
    "                                color: Color(0xFF162E35),\n"
    "                                fontWeight: FontWeight.w700,\n"
    "                              ),\n"
    "                            ),",
)

# ---- 4) Reiseprofil panel litt mer premium og mindre hard hvit ----
replace_once(
    "color: const Color(0xFFEFF7F8),",
    "color: const Color(0xFFEDF6F7),",
)
replace_once(
    "border: Border.all(color: const Color(0xFFD1E4E7)),",
    "border: Border.all(color: const Color(0xFFCFE1E5)),",
)

# ---- 5) Din poengstatus panel litt varmere premium ----
replace_once(
    "color: const Color(0xFFFAF6EC),",
    "color: const Color(0xFFF9F4E8),",
)
replace_once(
    "border: Border.all(color: const Color(0xFFE8D9B8)),",
    "border: Border.all(color: const Color(0xFFE5D4AE)),",
)

# ---- 6) Butikkseksjon hovedpanel mindre kritthvitt ----
replace_all(
    "color: const Color(0xFFF7FAFB),",
    "color: const Color(0xFFF2F8F9),",
)

# ---- 7) Butikkkort mer premium, men fortsatt lyse ----
replace_all(
    "Color(0xFFFFFFFF),",
    "Color(0xFFF9FCFC),",
)
replace_all(
    "Color(0xFFF8FCFD),",
    "Color(0xFFF1F8F9),",
)
replace_all(
    "color: const Color(0xFFDDE8EB),",
    "color: const Color(0xFFD5E4E7),",
)
replace_all(
    "color: Color(0x12000000),",
    "color: Color(0x10000000),",
)

# ---- 8) Tags litt mykere tonet bakgrunn ----
replace_all(
    "Color(0xFFE8F2F4)",
    "Color(0xFFE5F0F2)"
)

if text == orig or changes == 0:
    print("❌ Ingen sikre endringer ble gjort")
    print("Kjør og send:")
    print("  sed -n '885,1035p' lib/pages/travel_page.dart")
    print("  sed -n '520,700p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 805 ferdig, {changes} endringer brukt")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
