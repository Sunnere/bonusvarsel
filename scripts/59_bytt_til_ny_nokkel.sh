#!/bin/bash
set -euo pipefail
NEW_KEY_ID="${1:?Bruk: bash 59_bytt_til_ny_nokkel.sh <KEY_ID>}"
cd "$HOME/bonusvarsel"
SRC=$(ls "$HOME/Downloads"/*"$NEW_KEY_ID"*.p8 2>/dev/null | head -1 || true)
[ -n "$SRC" ] || { echo "FEIL: fant ingen .p8 med $NEW_KEY_ID i Nedlastinger"; exit 1; }

mkdir -p functions/keys
cp "$SRC" functions/keys/SubscriptionKey.p8
chmod 600 functions/keys/SubscriptionKey.p8

for F in functions/appstore_verify.js functions/index.js; do
  sed -i.tmp -E "s/const KEY_ID = \"[A-Z0-9]+\";/const KEY_ID = \"${NEW_KEY_ID}\";/" "$F"
  rm -f "$F.tmp"
  grep -n "const KEY_ID" "$F"
  node --check "$F"
done
echo "Syntaks OK. Nøkkel kopiert fra: $SRC"
