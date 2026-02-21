#!/usr/bin/env bash
set -euo pipefail

FILE="lib/models/shop_offer.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak.$(date +%s)" || true

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/models/shop_offer.dart")
s = p.read_text(encoding="utf-8")

before = s

# Fjern bare den typiske "unnecessary cast" i Map.from(...)
# Eksempler vi håndterer:
#   Map<String, dynamic>.from(x as Map)
#   Map<String, dynamic>.from(x as Map<dynamic, dynamic>)
#   Map<String, dynamic>.from(x as Map<Object?, Object?>)
patterns = [
    (r"Map<String,\s*dynamic>\.from\(\s*([^)]+?)\s+as\s+Map\s*\)", r"Map<String, dynamic>.from(\1)"),
    (r"Map<String,\s*dynamic>\.from\(\s*([^)]+?)\s+as\s+Map<[^>]+>\s*\)", r"Map<String, dynamic>.from(\1)"),
]

for pat, rep in patterns:
    s = re.sub(pat, rep, s)

if s == before:
    print("Ingen endring nødvendig (fant ikke mønsteret).")
else:
    p.write_text(s, encoding="utf-8")
    print("Fjernet unødvendig cast i shop_offer.dart")
PY

dart format "$FILE"
flutter analyze
