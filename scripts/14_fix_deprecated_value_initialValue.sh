#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak.$(date +%s)" || true

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")
before = s

# Bytt value: -> initialValue: i DropdownButtonFormField(...) blocks
# (Dette er den vanlige deprecationen i nyere Flutter.)
pattern = r"(DropdownButtonFormField<[^>]+>\s*\(\s*[\s\S]*?)(\bvalue\s*:\s*)"
def repl(m):
    return m.group(1) + "initialValue: "

s2 = re.sub(pattern, repl, s, count=50)

if s2 == before:
    # fallback: mer generell, men fortsatt ganske trygg: kun hvis det er DropdownButtonFormField( ... value:
    pattern2 = r"(DropdownButtonFormField\s*\(\s*[\s\S]*?)(\bvalue\s*:\s*)"
    s2 = re.sub(pattern2, repl, s, count=50)

p.write_text(s2, encoding="utf-8")

changed = (s2 != before)
print("Oppdatert value -> initialValue" if changed else "Ingen endring (fant ingen value: i DropdownButtonFormField).")
PY

dart format "$FILE"
flutter analyze
