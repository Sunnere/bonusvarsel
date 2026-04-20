#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

GOOD_BAK="$(
  ls -1t \
    lib/pages/eb_shopping_page.dart.bak_907.* \
    lib/pages/eb_shopping_page.dart.bak_906.* \
    lib/pages/eb_shopping_page.dart.bak_905.* \
    lib/pages/eb_shopping_page.dart.bak_904.* \
    2>/dev/null | head -n 1 || true
)"

if [[ -z "$GOOD_BAK" ]]; then
  echo "❌ Fant ingen egnet backup"
  echo "Kjør: ls -1t lib/pages/eb_shopping_page.dart.bak* | head -n 20"
  exit 1
fi

cp "$FILE" "$FILE.bak_909_before_restore.$(date +%s)"
cp "$GOOD_BAK" "$FILE"

echo "✅ Gjenopprettet fra: $GOOD_BAK"
echo

flutter analyze
echo "✅ 909 ferdig"
