#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_648_remove_inline_shopping_ad"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("lib/pages/eb_shopping_page.dart")
text = path.read_text()
original = text

patterns = [
    # Hele FutureBuilder-blokken for eb_shopping-annonsen
    r"""
(?P<block>
[ \t]*FutureBuilder<List<AdSlot>>\(
.*?
placement:\s*'eb_shopping'
.*?
[ \t]*\)\s*,?
)
""",
    # Alternativ: AdSlotCard direkte hvis FutureBuilder ikke matcher
    r"""
(?P<block>
[ \t]*AdSlotCard\(
.*?
placement:\s*'eb_shopping'
.*?
[ \t]*\)\s*,?
)
""",
]

removed = 0

for pat in patterns:
    while True:
        m = re.search(pat, text, flags=re.DOTALL | re.VERBOSE)
        if not m:
            break
        block = m.group('block')
        text = text.replace(block, "", 1)
        removed += 1

# Rydd litt ekstra luft
text = re.sub(r"\n{3,}", "\n\n", text)

if removed == 0:
    print("⚠️ Fant ingen eb_shopping-annonseblokk å fjerne.")
    sys.exit(2)

path.write_text(text)
print(f"✅ Fjernet {removed} eb_shopping-annonseblokk(er)")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
