#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
BACKUP="${FILE}.bak_648_remove_inline_shopping_ad"

if [ ! -f "$BACKUP" ]; then
  echo "❌ Fant ikke backup: $BACKUP"
  echo "Sjekk hvilke backups som finnes:"
  ls -1 "${FILE}".bak* 2>/dev/null || true
  exit 1
fi

cp "$BACKUP" "$FILE"
echo "✅ Gjenopprettet $FILE fra $BACKUP"

echo
echo "==> Kjør analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d 00008110-001138643E60401E"
