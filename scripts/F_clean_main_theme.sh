#!/usr/bin/env bash
set -euo pipefail

FILE="lib/main.dart"
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/main.dart")
s = p.read_text(encoding="utf-8")

# Fjern duplicate ThemeData-parametre
for field in [
    "surface:",
    "cardTheme:",
    "listTileTheme:",
    "inputDecorationTheme:"
]:
    lines = s.splitlines()
    seen = False
    new_lines = []
    for line in lines:
        if field in line:
            if seen:
                continue
            seen = True
        new_lines.append(line)
    s = "\n".join(new_lines)

# Fjern evt feilkomma etter siste param i ThemeData
s = re.sub(r",\s*\)", "\n)", s)

p.write_text(s, encoding="utf-8")
print("✅ Renset ThemeData for duplikater")
PY

dart format lib/main.dart
flutter analyze
