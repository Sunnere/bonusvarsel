#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_679_lighten_premium_safely"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

changed = False

old_bg = """    final bg = isElite
        ? (selected
            ? const Color(0xFF140F2A)
            : const Color(0xFF101826))
        : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80);"""

new_bg = """    final bg = isElite
        ? (selected
            ? const Color(0xFF140F2A)
            : const Color(0xFF101826))
        : (title == 'Premium'
            ? const Color(0xFFF6FAFF)
            : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80));"""

if old_bg in text:
    text = text.replace(old_bg, new_bg, 1)
    changed = True

old_border = """        : (emphasis
            ? (isElite
                ? const Color(0xFFD4AF37).withValues(alpha: 0.58)
                : accent.withValues(alpha: 0.45))
            : cs.onSurface.withValues(alpha: 0.36));"""

new_border = """        : (emphasis
            ? (isElite
                ? const Color(0xFFD4AF37).withValues(alpha: 0.58)
                : (title == 'Premium'
                    ? const Color(0xFF93C5FD)
                    : accent.withValues(alpha: 0.45)))
            : cs.onSurface.withValues(alpha: 0.36));"""

if old_border in text:
    text = text.replace(old_border, new_border, 1)
    changed = True

old_cta = "ctaColor: const Color(0xFF2563EB),"
new_cta = "ctaColor: const Color(0xFF60A5FA),"

if old_cta in text:
    text = text.replace(old_cta, new_cta, 1)
    changed = True

if not changed:
    print("⚠️ Fant ikke forventede Premium-mønstre. Ingen endring gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Premium lysnet trygt uten å røre tittelen")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "==> Verifiser Premium"
grep -n "F6FAFF\|93C5FD\|60A5FA\|title: 'Premium'" "$FILE" || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
