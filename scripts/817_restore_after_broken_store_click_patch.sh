#!/usr/bin/env bash
set -euo pipefail

echo "==> 817_restore_after_broken_store_click_patch"

TARGET="lib/pages/travel_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

BACKUP_FILE="$(ls -1t lib/pages/travel_page.dart.bak_*_817 2>/dev/null | head -1 || true)"
if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Fant ikke backup fra 817"
  echo "Kjør og send:"
  echo "  ls -1t lib/pages/travel_page.dart.bak_* | head -20"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BROKEN_BAK="${TARGET}.bak_${STAMP}_before_restore_817"

cp "$TARGET" "$BROKEN_BAK"
cp "$BACKUP_FILE" "$TARGET"

echo "✅ Gjenopprettet fra: $BACKUP_FILE"
echo "🗂 Backup av ødelagt fil: $BROKEN_BAK"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
