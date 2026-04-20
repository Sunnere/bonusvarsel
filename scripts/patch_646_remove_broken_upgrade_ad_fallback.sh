#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_646_remove_broken_upgrade_ad_fallback"
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
    r"""
[ \t]*const\s+SizedBox\(height:\s*16\),\n
[ \t]*//\s*Flyttet annonse: vises nær nivåvalg i stedet for midt i butikklisten\n
[ \t]*if\s*\(_upgradeAdSlot\s*!=\s*null\)\n
[ \t]*AdSlotCard\(\n
[ \t]*slot:\s*_upgradeAdSlot!,\n
[ \t]*placement:\s*'shopping_upgrade',\n
[ \t]*\),\n
[ \t]*const\s+SizedBox\(height:\s*16\),\n?
""",
    r"""
[ \t]*if\s*\(_upgradeAdSlot\s*!=\s*null\)\n
[ \t]*AdSlotCard\(\n
[ \t]*slot:\s*_upgradeAdSlot!,\n
[ \t]*placement:\s*'shopping_upgrade',\n
[ \t]*\),\n?
""",
]

changed = False
for pat in patterns:
    new_text, count = re.subn(
        pat,
        "",
        text,
        flags=re.VERBOSE,
    )
    if count > 0:
        text = new_text
        changed = True

# Ekstra sikkerhet: hvis navnet fortsatt finnes, erstatt bare referansene
if "_upgradeAdSlot" in text:
    text = text.replace("if (_upgradeAdSlot != null)", "if (false)")
    text = text.replace("slot: _upgradeAdSlot!,", "slot: slot,")
    changed = True

if not changed:
    print("⚠️ Fant ingen _upgradeAdSlot-blokk å fjerne. Ingen endring gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Fjernet ødelagt _upgradeAdSlot-fallback")
PY

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
