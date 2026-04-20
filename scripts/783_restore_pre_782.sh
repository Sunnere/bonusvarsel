#!/usr/bin/env bash
set -euo pipefail

echo "==> 783_restore_pre_782"

TARGET="lib/pages/travel_page.dart"

if [[ ! -f "$TARGET" ]]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

LATEST_782_BACKUP="$(ls -1t lib/pages/travel_page.dart.bak_*_782 2>/dev/null | head -1 || true)"

if [[ -z "$LATEST_782_BACKUP" ]]; then
  echo "❌ Fant ingen backup fra 782."
  echo "Kjør dette og send resultatet:"
  echo "  ls -1t lib/pages/travel_page.dart.bak_* | head -20"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BROKEN_BAK="${TARGET}.bak_${STAMP}_783_before_restore"

cp "$TARGET" "$BROKEN_BAK"
cp "$LATEST_782_BACKUP" "$TARGET"

echo "✅ Gjenopprettet fra:"
echo "   $LATEST_782_BACKUP"
echo "Backup av ødelagt fil:"
echo "   $BROKEN_BAK"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
