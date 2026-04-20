#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
BACKUP="lib/pages/premium_page.dart.bak_659_move_membership_above_plans_and_luxury_elite"

if [ ! -f "$BACKUP" ]; then
  echo "❌ Fant ikke backup: $BACKUP"
  exit 1
fi

cp "$BACKUP" "$FILE"
echo "✅ Gjenopprettet $FILE fra $BACKUP"

echo
echo "==> Kjør analyze"
flutter analyze || true
