#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak_move_ad_to_upgrade_$(date +%Y%m%d_%H%M%S)"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()

original = text

# 1) prøv å finne eksisterende AdSlotCard-blokk
ad_patterns = [
    r"\n\s*if\s*\([^\n]*ad[^\n]*\)\s*AdSlotCard\s*\([^\)]*\)\s*,?",
    r"\n\s*AdSlotCard\s*\([^\)]*\)\s*,?",
]

ad_match = None
for pat in ad_patterns:
    m = re.search(pat, text, flags=re.DOTALL)
    if m:
        ad_match = m
        break

if not ad_match:
    print("Fant ikke AdSlotCard-blokken. Ingen endring gjort.")
    sys.exit(2)

ad_block = ad_match.group(0)

# 2) fjern gammel annonse fra butikkflyten
text = text.replace(ad_block, "\n", 1)

# 3) legg inn ny annonse under nivåseksjon hvis mulig
inserted = False

markers = [
    r"(\n\s*const SizedBox\(height:\s*16\),\n\s*Text\(\s*'Kilde')",
    r"(\n\s*Text\(\s*'Kilde')",
    r"(\n\s*Wrap\([^\)]*Gratis[^\)]*Premium[^\)]*Elite[^\)]*\)\s*,?)",
]

new_block = """
                const SizedBox(height: 16),
                // Flyttet annonse: vises i oppgraderings-/nivåområdet i stedet for midt i butikkflyten
                AdSlotCard(
                  slot: _selectedTier == 'Elite'
                      ? _eliteUpgradeAdSlot
                      : _selectedTier == 'Premium'
                          ? _premiumUpgradeAdSlot
                          : _shoppingUpgradeAdSlot,
                  placement: _selectedTier == 'Elite'
                      ? 'elite_upgrade'
                      : _selectedTier == 'Premium'
                          ? 'premium_upgrade'
                          : 'shopping_upgrade',
                ),
                const SizedBox(height: 16),
"""

# Hvis statefelter ikke finnes, bruk enklere fallback
if "_selectedTier" not in text:
    new_block = """
                const SizedBox(height: 16),
                // Flyttet annonse: vises nær nivåvalg i stedet for midt i butikklisten
                if (_upgradeAdSlot != null)
                  AdSlotCard(
                    slot: _upgradeAdSlot!,
                    placement: 'shopping_upgrade',
                  ),
                const SizedBox(height: 16),
"""

for pat in markers:
    m = re.search(pat, text, flags=re.DOTALL)
    if m:
        idx = m.start(1)
        text = text[:idx] + new_block + text[idx:]
        inserted = True
        break

if not inserted:
    print("Fant ikke nivåseksjon å sette inn annonsen ved. Tilbakestiller.")
    sys.exit(3)

path.write_text(text)
print("OK: flyttet annonseblokk fra butikkflyt til nivåområde")
PY

echo "Kjører flutter analyze..."
flutter analyze
