#!/usr/bin/env bash
set -euo pipefail

echo "==> 804_upgrade_store_cards_to_premium_soft"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_804")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

changes = 0

def replace_all(old: str, new: str):
    global text, changes
    count = text.count(old)
    if count:
        text = text.replace(old, new)
        changes += count

# Oppgrader butikk-kort bakgrunn
replace_all(
    "color: Colors.white,",
    "color: const Color(0xFFF7FAFB),",
)

# Litt mer premium border
replace_all(
    "border: Border.all(color: const Color(0xFFE6ECEF)),",
    "border: Border.all(color: const Color(0xFFD6E6EA)),",
)

# Legg til shadow hvis finnes BoxDecoration uten shadow
replace_all(
"""decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD6E6EA)),
                ),""",
"""decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD6E6EA)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),""",
)

# Gjør CTA knapp litt mer premium (ikke mørkere)
replace_all(
    "Color(0xFF103562)",
    "Color(0xFF0F3A4A)",
)

replace_all(
    "Color(0xFF1294A4)",
    "Color(0xFF1FA6B6)",
)

# Litt mer kontrast i tags
replace_all(
    "Color(0xFFEFF3F5)",
    "Color(0xFFE8F2F4)",
)

if text == orig or changes == 0:
    print("❌ Ingen endringer gjort")
    print("Kjør:")
    print("  sed -n '1030,1180p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 804 ferdig, {changes} forbedringer lagt til")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
