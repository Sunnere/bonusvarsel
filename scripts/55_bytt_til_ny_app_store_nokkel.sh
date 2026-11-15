#!/bin/bash
set -euo pipefail
cd "$HOME/bonusvarsel"
F="functions/appstore_verify.js"
NEW_KEY_ID="ZQF632P8J4"
SRC="$HOME/Downloads/SubscriptionKey_${NEW_KEY_ID}.p8"
DST="functions/keys/SubscriptionKey.p8"

# 1. Bytt hardkodet Key ID
if grep -q "const KEY_ID = \"${NEW_KEY_ID}\"" "$F"; then
  echo "Key ID er allerede ${NEW_KEY_ID}"
else
  sed -i '' "s/const KEY_ID = \"[A-Z0-9]*\";/const KEY_ID = \"${NEW_KEY_ID}\";/" "$F"
fi
grep -n "const KEY_ID" "$F"

# 2. Syntakssjekk
node --check "$F"
echo "Syntaks OK"

# 3. Flytt nøkkel på plass
mkdir -p functions/keys
if [ -f "$SRC" ]; then
  mv "$SRC" "$DST"
  echo "Flyttet nøkkel til $DST"
fi
if [ ! -f "$DST" ]; then
  echo "FEIL: finner ikke $DST eller $SRC"
  exit 1
fi
chmod 600 "$DST"

# 4. Kontroller format (viser kun første linje) og git-ignorering
head -1 "$DST"
git check-ignore -v "$DST" || { echo "FEIL: functions/keys er ikke ignorert"; exit 1; }
echo "Ferdig. Neste: firebase deploy --only functions:verifyAppStorePurchase"
