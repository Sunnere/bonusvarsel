#!/usr/bin/env bash
set -euo pipefail

python - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/eb_shopping_page.dart")
s = path.read_text(encoding="utf-8")

# 1) Sikre at vi har primary fargen definert i build (eller rett over chips)
# Vi setter en enkel 'final primary = ...' i build() hvis den mangler.
if "final primary = const Color(0xFF0A2F6B);" not in s:
    # prøv å putte den rett etter: Widget build(BuildContext context) {
    s = re.sub(
        r"(Widget build\(BuildContext context\)\s*\{\s*)",
        r"\1\n    final primary = const Color(0xFF0A2F6B);\n",
        s,
        count=1,
    )

# 2) Bytt ut "Kun kampanjer" chip uansett gammel variant (robust regex).
# Vi matcher en FilterChip(...) som inneholder teksten "Kun kampanjer" og erstatter hele chip-en.
pattern_kun = r"FilterChip\([\s\S]*?Kun kampanjer[\s\S]*?\)\s*,"
replacement_kun = """FilterChip(
                    label: Text(
                      'Kun kampanjer',
                      style: TextStyle(
                        color: _onlyCampaigns ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _onlyCampaigns,
                    onSelected: (v) => setState(() => _onlyCampaigns = v),
                    selectedColor: primary,
                    backgroundColor: Colors.grey.shade200,
                    checkmarkColor: Colors.white,
                    showCheckmark: true,
                  ),"""
s2 = re.sub(pattern_kun, replacement_kun, s, flags=re.M)
s = s2

# 3) Bytt ut "Favoritter først" chip.
pattern_fav = r"FilterChip\([\s\S]*?Favoritter først[\s\S]*?\)\s*,"
replacement_fav = """FilterChip(
                    label: Text(
                      'Favoritter først',
                      style: TextStyle(
                        color: _favFirst ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: _favFirst,
                    onSelected: (v) => setState(() => _favFirst = v),
                    selectedColor: primary,
                    backgroundColor: Colors.grey.shade200,
                    checkmarkColor: Colors.white,
                    showCheckmark: true,
                  ),"""
s = re.sub(pattern_fav, replacement_fav, s, flags=re.M)

path.write_text(s, encoding="utf-8")
print("✅ Chips patched: hvit tekst når valgt (Kun kampanjer / Favoritter først)")
PY

dart format lib/pages/eb_shopping_page.dart
flutter analyze || true
