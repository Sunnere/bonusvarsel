#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_888.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old = """        const SizedBox(width: 10),
        // BV_BOOST_UPGRADE_BTN
        _UpgradeCtaButton(
          onPressed: () => _openPremiumPage(context),
          label: ctaLabel,
        ),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke eksakt Boost/Oppgrader-blokk")

text = text.replace(old, "", 1)

p.write_text(text)
print("✅ Fjernet eksakt Boost/Oppgrader-knapp")
PY

flutter analyze
echo "✅ 888 ferdig"
