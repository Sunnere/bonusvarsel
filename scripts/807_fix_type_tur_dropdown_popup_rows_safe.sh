#!/usr/bin/env bash
set -euo pipefail

echo "==> 807_fix_type_tur_dropdown_popup_rows_safe"

python3 <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

path = Path("lib/pages/travel_page.dart")
text = path.read_text()
orig = text

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
bak = path.with_name(path.name + f".bak_{stamp}_807")
shutil.copy2(path, bak)
print(f"Backup: {bak}")

old = """                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,
                      dropdownColor: const Color(0xFFF6FAFB),
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Type tur',
                        filled: true,
                        fillColor: const Color(0xFFF3F8F9),
                        labelStyle: const TextStyle(
                          color: Color(0xFF27414A),
                          fontWeight: FontWeight.w700,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD4E1E5)),
                        ),
                      ),
                      items: _tripThemes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Color(0xFF162E35),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedTripTheme = v);
                      },
                    ),
"""

new = """                    DropdownButtonFormField<String>(
                      initialValue: _selectedTripTheme,
                      dropdownColor: const Color(0xFFEFF7F8),
                      style: const TextStyle(
                        color: Color(0xFF162E35),
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Type tur',
                        filled: true,
                        fillColor: const Color(0xFFF3F8F9),
                        labelStyle: const TextStyle(
                          color: Color(0xFF27414A),
                          fontWeight: FontWeight.w700,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD4E1E5)),
                        ),
                      ),
                      items: _tripThemes
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF7F8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    color: Color(0xFF162E35),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedTripTheme = v);
                      },
                    ),
"""

if old not in text:
    print("❌ Fant ikke eksakt Type tur-blokk")
    print("Kjør og send:")
    print("  sed -n '900,965p' lib/pages/travel_page.dart")
    raise SystemExit(1)

text = text.replace(old, new, 1)

if text == orig:
    print("❌ Ingen endring gjort")
    raise SystemExit(1)

path.write_text(text)
print("✅ 807 ferdig: Type tur-popupen har fått tonede meny-rader")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
