#!/usr/bin/env bash
set -euo pipefail

FILE="lib/main.dart"

# Vi bytter chipTheme til mer tydelig kontrast (selected = primary + hvit tekst)
python - <<'PY'
from pathlib import Path
import re

p = Path("lib/main.dart")
s = p.read_text(encoding="utf-8")

# Finn chipTheme: ChipThemeData(...) og erstatt hele blokken med en bedre variant
pattern = r"chipTheme:\s*ChipThemeData\([\s\S]*?\),\n"
replacement = """chipTheme: ChipThemeData(
          backgroundColor: Colors.grey.shade200,
          selectedColor: const Color(0xFF0A2F6B),
          disabledColor: Colors.grey.shade100,
          labelStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
"""

if re.search(pattern, s):
    s = re.sub(pattern, replacement, s, count=1)
else:
    # Hvis chipTheme ikke finnes, legg den inn i ThemeData( ... ) rett etter appBarTheme
    s = s.replace("appBarTheme:", "appBarTheme:", 1)

p.write_text(s, encoding="utf-8")
print("✅ chipTheme oppdatert i lib/main.dart")
PY

dart format lib/main.dart
flutter analyze
