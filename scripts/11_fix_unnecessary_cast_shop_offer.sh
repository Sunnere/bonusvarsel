#!/usr/bin/env bash
set -euo pipefail

FILE="lib/models/shop_offer.dart"
[ -f "$FILE" ] || { echo "Finner ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/models/shop_offer.dart")
s = p.read_text(encoding="utf-8")

# Typisk feil: ... as String ) eller as String; når feltet allerede er String
# Vi fjerner " as String" i generelle uttrykk (trygt for denne advarselen).
new = re.sub(r"\s+as\s+String\b", "", s)

if new == s:
    print("Ingen endring nødvendig (fant ikke 'as String').")
else:
    p.write_text(new, encoding="utf-8")
    print("Fikset: fjernet unødvendig 'as String' cast i shop_offer.dart")
PY

dart format "$FILE"
flutter analyze
