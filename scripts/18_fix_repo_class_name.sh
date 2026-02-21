#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }
cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# Bytt EBRepository -> EbRepository (klasse + ctor)
s = s.replace("EBRepository", "EbRepository")

p.write_text(s, encoding="utf-8")
print("✅ Patchet EBRepository -> EbRepository i eb_shopping_page.dart")
PY

dart format "$FILE"
flutter analyze
