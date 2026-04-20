#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_653_add_upgrade_ad_to_premium_page"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

# 1) imports
if "package:bonusvarsel/widgets/ad_slot.dart" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\n"
        "import 'package:bonusvarsel/widgets/ad_slot.dart';\n"
        "import 'package:bonusvarsel/services/ad_service.dart';\n"
        "import 'package:bonusvarsel/models/ad_slot.dart';\n"
    )

# 2) inject ad block after _ValueBar(...)
old = """                    _ValueBar(
                      accent: accent,
                      leftTitle: 'Typisk gevinst',
                      leftBody:
                          'Du mister ekstra poeng hver gang du handler uten Premium/Elite.',
                      rightTitle: 'Mål',
                      rightBody:
                          'Gjør det lett å samle nok poeng til billigere (eller gratis) reiser.',
                    ),

                    const SizedBox(height: 16),"""

new = """                    _ValueBar(
                      accent: accent,
                      leftTitle: 'Typisk gevinst',
                      leftBody:
                          'Du mister ekstra poeng hver gang du handler uten Premium/Elite.',
                      rightTitle: 'Mål',
                      rightBody:
                          'Gjør det lett å samle nok poeng til billigere (eller gratis) reiser.',
                    ),

                    const SizedBox(height: 14),
                    FutureBuilder<List<AdSlot>>(
                      future: AdService.instance.pickAds(
                        placement: 'elite_top_cards',
                        count: 1,
                      ),
                      builder: (context, snap) {
                        final ads = snap.data ?? const <AdSlot>[];
                        if (ads.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: AdSlotCard(
                            slot: ads.first,
                            placement: 'elite_top_cards',
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),"""

if old not in text:
    print("❌ Fant ikke eksakt _ValueBar-blokk. Ingen endring gjort.")
    sys.exit(1)

text = text.replace(old, new, 1)

if text == original:
    print("⚠️ Ingen endring ble gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ La inn annonse under Typisk gevinst / Mål i premium_page.dart")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
