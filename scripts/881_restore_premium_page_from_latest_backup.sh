#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

LATEST_BAK="$(ls -1t lib/pages/premium_page.dart.bak* 2>/dev/null | head -n 1 || true)"
if [[ -z "$LATEST_BAK" ]]; then
  echo "❌ Fant ingen backup for $FILE"
  exit 1
fi

cp "$FILE" "$FILE.bak_881_before_restore.$(date +%s)"
cp "$LATEST_BAK" "$FILE"

echo "✅ Gjenopprettet fra: $LATEST_BAK"
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
echo "✅ 881 ferdig"
