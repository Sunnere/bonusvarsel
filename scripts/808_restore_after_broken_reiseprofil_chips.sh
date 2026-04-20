#!/usr/bin/env bash
set -euo pipefail

echo "==> 808_restore_after_broken_reiseprofil_chips"

TARGET="lib/pages/travel_page.dart"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

pick_backup() {
  local candidate

  candidate="$(ls -1t lib/pages/travel_page.dart.bak_*_807 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return
  fi

  candidate="$(ls -1t lib/pages/travel_page.dart.bak_*_806 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return
  fi

  candidate="$(ls -1t lib/pages/travel_page.dart.bak_*_805 2>/dev/null | head -1 || true)"
  if [ -n "$candidate" ]; then
    echo "$candidate"
    return
  fi

  echo ""
}

BACKUP_FILE="$(pick_backup)"

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ Fant ingen trygg backup (_807/_806/_805)"
  echo "Kjør dette og send resultatet:"
  echo "  ls -1t lib/pages/travel_page.dart.bak_* | head -20"
  exit 1
fi

STAMP="$(date +%Y%m%d_%H%M%S)"
BROKEN_BAK="${TARGET}.bak_${STAMP}_before_restore_808"

cp "$TARGET" "$BROKEN_BAK"
cp "$BACKUP_FILE" "$TARGET"

echo "✅ Gjenopprettet travel_page.dart fra:"
echo "   $BACKUP_FILE"
echo
echo "Backup av ødelagt fil:"
echo "   $BROKEN_BAK"
echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
