#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

BACKUP="${FILE}.bak_676_refine_elite_vs_premium_visual_hierarchy"
cp "$FILE" "$BACKUP"
echo "✅ Backup laget: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
original = text

changed = False

repls = [
    (
        "            ? const Color(0xFF1A1333)\n            : const Color(0xFF141B29))",
        "            ? const Color(0xFF140F2A)\n            : const Color(0xFF101826))"
    ),
    (
        "                            Color(0xFF24164A),\n                            Color(0xFF17132E),\n                            Color(0xFF101826),",
        "                            Color(0xFF2A1754),\n                            Color(0xFF16112F),\n                            Color(0xFF0D1522),"
    ),
    (
        "            border: Border.all(color: borderColor, width: isElite ? 1.5 : 1.0),",
        "            border: Border.all(color: borderColor, width: isElite ? 1.8 : 1.0),"
    ),
    (
        "                    ? const Color(0xFFD4AF37).withValues(alpha: selected ? 0.16 : 0.08)",
        "                    ? const Color(0xFFD4AF37).withValues(alpha: selected ? 0.22 : 0.10)"
    ),
    (
        "                blurRadius: isElite ? 24 : 16,",
        "                blurRadius: isElite ? 30 : 16,"
    ),
    (
        "                          color: isElite ? const Color(0xFFFFE7A3) : null,",
        "                          color: isElite ? const Color(0xFFFFE08A) : null,"
    ),
    (
        "                          letterSpacing: isElite ? 0.2 : null,",
        "                          letterSpacing: isElite ? 0.35 : null,"
    ),
    (
        "                          ? const Color(0xFFD4AF37).withValues(alpha: 0.18)",
        "                          ? const Color(0xFFD4AF37).withValues(alpha: 0.24)"
    ),
    (
        "                            ? const Color(0xFFD4AF37).withValues(alpha: 0.62)",
        "                            ? const Color(0xFFD4AF37).withValues(alpha: 0.78)"
    ),
    (
        "          ctaColor: const Color(0xFF22C55E),",
        "          ctaColor: const Color(0xFF2563EB),"
    ),
]

for old, new in repls:
    if old in text:
        text = text.replace(old, new, 1)
        changed = True

if not changed:
    print("⚠️ Fant ingen forventede mønstre å justere.")
    sys.exit(2)

path.write_text(text)
print("✅ Finjusterte Elite/Premium-hierarkiet")
PY

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
