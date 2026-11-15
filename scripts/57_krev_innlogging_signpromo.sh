#!/bin/bash
set -euo pipefail
cd "$HOME/bonusvarsel"
F="functions/index.js"
BAK="$HOME/Desktop/index.js.bak57"
SIG='exports.signPromoOffer = functions.https.onCall(async (data, context) => {'
CHECK='  if (!context || !context.auth) throw new functions.https.HttpsError("unauthenticated", "Innlogging kreves.");'

if grep -qF "Innlogging kreves" "$F"; then
  echo "Innloggingssjekk finnes allerede i $F"
  exit 0
fi
if ! grep -qF "$SIG" "$F"; then
  echo "FEIL: fant ikke signPromoOffer-linjen i $F"; exit 1
fi

cp "$F" "$BAK"
awk -v sig="$SIG" -v chk="$CHECK" '
  { print }
  index($0, sig) > 0 { print chk }
' "$BAK" > "$F"

grep -n -A1 "exports.signPromoOffer" "$F"
node --check "$F" && echo "Syntaks OK. Backup: $BAK"
