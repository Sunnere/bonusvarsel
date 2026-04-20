#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
BACKUP="${FILE}.bak_677_lighten_premium_card"

if [ ! -f "$BACKUP" ]; then
  echo "❌ Fant ikke backup: $BACKUP"
  exit 1
fi

cp "$BACKUP" "$FILE"
echo "✅ Gjenopprettet $FILE fra $BACKUP"

echo
echo "==> flutter analyze"
flutter analyze || true
