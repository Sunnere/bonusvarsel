#!/bin/bash
set -euo pipefail
cd "$HOME/bonusvarsel"
F="functions/index.js"
NEW="ZQF632P8J4"

if grep -q "const KEY_ID = \"${NEW}\"" "$F"; then
  echo "Allerede ${NEW} i $F"
  exit 0
fi

if ! grep -q 'const KEY_ID = "WNU3742ZH9"' "$F"; then
  echo "FEIL: fant ikke forventet KEY_ID-linje i $F. Lim inn: grep -n KEY_ID $F"
  exit 1
fi

sed -i '' "s/const KEY_ID = \"WNU3742ZH9\"/const KEY_ID = \"${NEW}\"/" "$F"
grep -n "const KEY_ID" "$F"
node --check "$F" && echo "Syntaks OK"
