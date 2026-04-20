#!/usr/bin/env bash
set -euo pipefail

echo "==> 802_fix_input_text_colors_only"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_802")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

changes = 0

def replace_once(old: str, new: str):
    global text, changes
    if old in text:
        text = text.replace(old, new, 1)
        changes += 1

# Reisemål TextField
replace_once(
"""                    TextField(
                      controller: _destinationCtrl,
                      decoration: InputDecoration(
""",
"""                    TextField(
                      controller: _destinationCtrl,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
""",
)

# Type tur dropdown
replace_once(
"""                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,
                      decoration: InputDecoration(
""",
"""                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
""",
)

# Voksne dropdown
replace_once(
"""                          child: DropdownButtonFormField<int>(
                            initialValue: _adults,
                            decoration: InputDecoration(
""",
"""                          child: DropdownButtonFormField<int>(
                            initialValue: _adults,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF162E35),
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
""",
)

# Barn dropdown
replace_once(
"""                          child: DropdownButtonFormField<int>(
                            initialValue: _children,
                            decoration: InputDecoration(
""",
"""                          child: DropdownButtonFormField<int>(
                            initialValue: _children,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF162E35),
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
""",
)

# Antall dager dropdown
replace_once(
"""                    DropdownButtonFormField<int>(
                      initialValue: _days,
                      decoration: InputDecoration(
""",
"""                    DropdownButtonFormField<int>(
                      initialValue: _days,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
""",
)

# SAS poeng TextField
replace_once(
"""                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
""",
"""                    TextField(
                      controller: _sasPointsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
""",
)

if text == orig or changes == 0:
    print("❌ Fant ingen av blokkene for tekstfarge-fix")
    raise SystemExit(1)

path.write_text(text)
print(f"✅ 802 ferdig, {changes} målrettede endringer brukt")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
