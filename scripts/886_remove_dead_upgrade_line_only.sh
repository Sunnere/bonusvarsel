#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_886.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

patterns = [
    r"\n\s*const _UpgradeCtaButton\([^)]*\),",
    r"\n\s*_UpgradeCtaButton\([^)]*\),",
    r"\n\s*const SizedBox\(height:\s*12\),\n\s*_UpgradeCtaButton\([^)]*\),",
]

changed = False
for pat in patterns:
    new_text = re.sub(pat, "", text, flags=re.MULTILINE)
    if new_text != text:
        text = new_text
        changed = True

if not changed:
    raise SystemExit("❌ Fant ikke _UpgradeCtaButton-bruken i widget-treet")

p.write_text(text)
print("✅ Fjernet død Oppgrader-linje")
PY

flutter analyze
echo "✅ 886 ferdig"
