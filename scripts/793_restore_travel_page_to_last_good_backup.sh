#!/usr/bin/env bash
set -euo pipefail

echo "==> 793_restore_travel_page_to_last_good_backup"

TARGET="lib/pages/travel_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

pick_backup() {
  local candidate

  candidate="$(ls -1t lib/pages/travel_page.dart.bak_*_792 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return
  fi

  candidate="$(ls -1t lib/pages/travel_page.dart.bak_*_791 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return
  fi

  candidate="$(ls -1t lib/pages/travel_page.dart.bak_*_790 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return
  fi

  candidate="$(ls -1t lib/pages/travel_page.dart.bak_* 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return
  fi

  echo ""
}

BACKUP_FILE="$(pick_backup)"

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Fant ingen backup-fil for travel_page.dart"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BROKEN_BAK="${TARGET}.bak_${STAMP}_before_restore"

cp "$TARGET" "$BROKEN_BAK"
cp "$BACKUP_FILE" "$TARGET"

echo "✅ Gjenopprettet fra backup:"
echo "   $BACKUP_FILE"
echo
echo "Backup av ødelagt fil:"
echo "   $BROKEN_BAK"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
