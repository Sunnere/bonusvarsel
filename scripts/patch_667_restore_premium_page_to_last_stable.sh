#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
BACKUP="lib/pages/premium_page.dart.bak_659_move_membership_above_plans_and_luxury_elite"

if [ ! -f "$BACKUP" ]; then
  echo "❌ Fant ikke backup: $BACKUP"
  echo
  echo "Tilgjengelige backups:"
  ls -1 "${FILE}".bak* 2>/dev/null || true
  exit 1
fi

cp "$BACKUP" "$FILE"
echo "✅ Gjenopprettet $FILE fra:"
echo "   $BACKUP"

echo
echo "==> Kontrollerer området som var ødelagt"
nl -ba "$FILE" | sed -n '500,540p' || true

echo
echo "==> Kjør flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Kjør nå:"
echo "  flutter run -d 00008110-001138643E60401E"
