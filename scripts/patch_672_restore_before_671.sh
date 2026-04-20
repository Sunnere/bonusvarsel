#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
BACKUP="${FILE}.bak_671_remove_bottom_premium_cta_and_force_elite_luxury"

if [ ! -f "$BACKUP" ]; then
  echo "❌ Fant ikke backup: $BACKUP"
  ls -1 "${FILE}".bak* 2>/dev/null || true
  exit 1
fi

cp "$BACKUP" "$FILE"
echo "✅ Gjenopprettet $FILE fra $BACKUP"

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "==> Utdrag rundt mulig CTA / elite-kort"
nl -ba "$FILE" | sed -n '520,590p' || true
