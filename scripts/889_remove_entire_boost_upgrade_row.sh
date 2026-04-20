#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_889.$(date +%s)"
echo "✅ Backup laget: $FILE"

python3 <<'PY'
from pathlib import Path

p = Path("lib/pages/eb_shopping_page.dart")
text = p.read_text()
orig = text

old = """          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boost',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                lockedLine,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // BV_BOOST_UPGRADE_BTN
        _UpgradeCtaButton(
          onPressed: () => _openPremiumPage(context),
          label: ctaLabel,
        ),
"""

if old not in text:
    raise SystemExit("❌ Fant ikke eksakt Boost-rad å fjerne")

text = text.replace(old, "", 1)

p.write_text(text)
print("✅ Fjernet hele Boost/oppgrader-raden")
PY

flutter analyze
echo "✅ 889 ferdig"
