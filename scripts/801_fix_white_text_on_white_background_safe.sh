#!/usr/bin/env bash
set -euo pipefail

echo "==> 801_fix_white_text_on_white_background_safe"

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
bak = path.with_name(path.name + f".bak_{stamp}_801")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

changes = 0

def replace_once(old: str, new: str):
    global text, changes
    if old in text:
        text = text.replace(old, new, 1)
        changes += 1

# Reisemål
replace_once(
"""                    TextField(
                      controller: _destinationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reisemål',
                        hintText: 'f.eks Bangkok',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
""",
"""                    TextField(
                      controller: _destinationCtrl,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Reisemål',
                        hintText: 'f.eks Bangkok',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFFFFFFF),
                        labelStyle: TextStyle(
                          color: Color(0xFF29424A),
                          fontWeight: FontWeight.w700,
                        ),
                        hintStyle: TextStyle(
                          color: Color(0xFF70858C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
""",
)

# SAS poengfelt
replace_once(
"""                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        contentPadding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
""",
"""                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        contentPadding: EdgeInsets.fromLTRB(16, 24, 16, 14),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFFFFFFF),
                        labelStyle: TextStyle(
                          color: Color(0xFF29424A),
                          fontWeight: FontWeight.w800,
                        ),
                        hintStyle: TextStyle(
                          color: Color(0xFF70858C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
""",
)

# fallback hvis SAS-feltet er enklere
replace_once(
"""                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
""",
"""                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nåværende SAS EuroBonus-poeng',
                        hintText: 'f.eks 36797',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFFFFFFF),
                        labelStyle: TextStyle(
                          color: Color(0xFF29424A),
                          fontWeight: FontWeight.w800,
                        ),
                        hintStyle: TextStyle(
                          color: Color(0xFF70858C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
""",
)

# Dropdowns i Reiseprofil - legg til mørk tekst + hvit bakgrunn
labels = ["Type tur", "Voksne", "Barn", "Antall dager"]
for label in labels:
    replace_once(
f"""                      decoration: const InputDecoration(
                        labelText: '{label}',
                        border: OutlineInputBorder(),
                      ),
""",
f"""                      decoration: const InputDecoration(
                        labelText: '{label}',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFFFFFFF),
                        labelStyle: TextStyle(
                          color: Color(0xFF29424A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
""",
    )
    replace_once(
f"""                            decoration: const InputDecoration(
                              labelText: '{label}',
                              border: OutlineInputBorder(),
                            ),
""",
f"""                            decoration: const InputDecoration(
                              labelText: '{label}',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Color(0xFFFFFFFF),
                              labelStyle: TextStyle(
                                color: Color(0xFF29424A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF162E35),
                              fontWeight: FontWeight.w700,
                            ),
""",
    )

if text == orig or changes == 0:
    print("❌ Fant ikke de forventede input-/dropdown-blokkene")
    print("Kjør og send:")
    print("  sed -n '860,1015p' lib/pages/travel_page.dart")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 801 ferdig, {changes} sikre endringer brukt")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
