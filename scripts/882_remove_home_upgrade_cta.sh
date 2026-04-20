#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_882.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

# Fjern widget-bruk hvis den ligger i widgettreet
patterns = [
    r"\n\s*_UpgradeCtaButton\(\s*onPressed:\s*[^,]+,\s*label:\s*'[^']+'\s*,?\s*\),",
    r'\n\s*_UpgradeCtaButton\(\s*onPressed:\s*[^,]+,\s*label:\s*"[^"]+"\s*,?\s*\),',
]

for pat in patterns:
    text = re.sub(pat, "", text, flags=re.MULTILINE)

# Hvis teksten brukes direkte i UI et sted
text = text.replace("'Oppgrader'", "'Mer info'")
text = text.replace('"Oppgrader"', '"Mer info"')

if text == orig:
    raise SystemExit("❌ Fant ingen Oppgrader-CTA å fjerne")

p.write_text(text)
print("✅ Fjernet hjem-CTA for Oppgrader")
PY

flutter analyze
echo "✅ 882 ferdig"
