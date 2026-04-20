#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_887.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old = """        _UpgradeCtaButton(
          onPressed: _selectedPlan == _Plan.free ? _goPremium : null,
          label: ctaLabel,
        ),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke den spesifikke _UpgradeCtaButton-blokken")

text = text.replace(old, "", 1)

p.write_text(text)
print("✅ Fjernet den spesifikke Oppgrader-linjen")
PY

flutter analyze
echo "✅ 887 ferdig"
