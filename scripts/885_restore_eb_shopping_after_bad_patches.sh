#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

GOOD_BAK="$(
  ls -1t \
    lib/pages/eb_shopping_page.dart.bak_879.* \
    lib/pages/eb_shopping_page.dart.bak_878.* \
    lib/pages/eb_shopping_page.dart.bak.1774077832 \
    lib/pages/eb_shopping_page.dart.bak.1774021846 \
    2>/dev/null | head -n 1 || true
)"

if [[ -z "$GOOD_BAK" ]]; then
  echo "❌ Fant ingen kjent god backup for eb_shopping_page.dart"
  echo "Kjør:"
  echo "  ls -1t lib/pages/eb_shopping_page.dart.bak* | head -n 20"
  exit 1
fi

cp "$FILE" "$FILE.bak_885_before_restore.$(date +%s)"
cp "$GOOD_BAK" "$FILE"

echo "✅ Gjenopprettet fra: $GOOD_BAK"
echo

echo "== Sjekker konfliktmarkører =="
if grep -nE '^(<<<<<<<|=======|>>>>>>>)' "$FILE"; then
  echo "❌ Fant konfliktmarkører"
  exit 1
else
  echo "✅ Ingen konfliktmarkører"
fi

echo
flutter analyze
echo "✅ 885 ferdig"
