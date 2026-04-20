#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_651_disable_eb_shopping_ad_block"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()

old = """  return FutureBuilder<List<AdSlot>>(
    future: AdService.instance.pickAds(placement: 'eb_shopping'),
    builder: (context, snap) {
      final list = snap.data ?? const <AdSlot>[];
      if (list.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: AdSlotCard(
          slot: list.first,
          placement: 'eb_shopping',
        ),
      );
    },
  );
}"""

new = """  return const SizedBox.shrink();
}"""

if old not in text:
    print("❌ Fant ikke eksakt eb_shopping-blokk. Ingen endring gjort.")
    sys.exit(1)

text = text.replace(old, new, 1)
path.write_text(text)
print("✅ Deaktiverte eb_shopping-annonsen i eb_shopping_page.dart")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
