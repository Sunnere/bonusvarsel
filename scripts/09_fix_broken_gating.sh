#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[ -f "$FILE" ] || { echo "Fant ikke $FILE"; exit 1; }

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# Fjern feil \upgradeBanner
s = s.replace("\\upgradeBanner,", "")
s = s.replace("\\upgradeBanner", "")

# Fjern FREE_LIMIT-blokk hvis den ble feil injisert
s = re.sub(r"const FREE_LIMIT = 30;[\s\S]*?upgradeBanner[\s\S]*?;\n", "", s)

# Bytt tilbake limited -> filtered hvis nødvendig
s = s.replace("limited.length", "filtered.length")
s = s.replace("limited[i]", "filtered[i]")

p.write_text(s, encoding="utf-8")
print("✅ Ryddet opp ødelagt gating.")
PY

dart format lib/pages/eb_shopping_page.dart
flutter analyze
