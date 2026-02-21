#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/eb_repository.dart"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/services/eb_repository.dart")
s = p.read_text(encoding="utf-8")

orig = s

# Fjern typiske unødvendige casts fra SharedPreferences (analyzer klager ofte på disse)
s = re.sub(r'(prefs\.getString\([^)]+\))\s+as\s+String\??', r'\1', s)
s = re.sub(r'(prefs\.getInt\([^)]+\))\s+as\s+int\??', r'\1', s)
s = re.sub(r'(prefs\.getDouble\([^)]+\))\s+as\s+double\??', r'\1', s)
s = re.sub(r'(prefs\.getBool\([^)]+\))\s+as\s+bool\??', r'\1', s)

if s == orig:
    print("Ingen matching casts funnet å fjerne (OK).")
else:
    p.write_text(s, encoding="utf-8")
    print("Fjernet unnecessary casts i", p)
PY

dart format "$FILE"
flutter analyze
