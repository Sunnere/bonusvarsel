#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_677_lighten_premium_card"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

changed = False

# 1) Gjør Premium bakgrunn lysere
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
            ? cs.surface.withValues(alpha: 0.97)
            : cs.surface.withValues(alpha: emphasis ? 0.92 : 0.80));"""

if old_bg in text:
    text = text.replace(old_bg, new_bg, 1)
    changed = True

# 2) Mykere border på Premium
old_border = """        : (emphasis
            ? (isElite
                ? const Color(0xFFD4AF37).withValues(alpha: 0.58)
                : accent.withValues(alpha: 0.45))
            : cs.onSurface.withValues(alpha: 0.36));"""

new_border = """        : (emphasis
            ? (isElite
                ? const Color(0xFFD4AF37).withValues(alpha: 0.58)
                : (title == 'Premium'
                    ? accent.withValues(alpha: 0.28)
                    : accent.withValues(alpha: 0.45)))
            : cs.onSurface.withValues(alpha: 0.36));"""

if old_border in text:
    text = text.replace(old_border, new_border, 1)
    changed = True

# 3) Litt lysere tekst på Premium
old_title = """                          color: isElite ? const Color(0xFFFFE08A) : null,"""

new_title = """                          color: isElite
                              ? const Color(0xFFFFE08A)
                              : (title == 'Premium'
                                  ? const Color(0xFF0F172A)
                                  : null),"""

if old_title in text:
    text = text.replace(old_title, new_title, 1)
    changed = True

# 4) Premium CTA mer clean blå
old_cta = "const Color(0xFF2563EB)"
new_cta = "const Color(0xFF3B82F6)"

if old_cta in text:
    text = text.replace(old_cta, new_cta, 1)
    changed = True

if not changed:
    print("⚠️ Fant ikke Premium-mønstre. Ingen endring gjort.")
    sys.exit(2)

path.write_text(text)
print("✅ Premium gjort lysere og renere")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør:"
echo "  flutter run -d 00008110-001138643E60401E"
