#!/usr/bin/env bash
# 17_fix_premium_stripe_link.sh
# Retter Premium-knappen i premium_page.dart: den pekte til Elite-lenken (89 kr).
# Elite   = bJecN600a8j8f7P8bvcQU06 (89 kr/mnd)
# Premium = 9B65kE28i7f44tbcrLcQU05 (49 kr/mnd)
# Bruk: bash scripts/17_fix_premium_stripe_link.sh [app-mappe]   (default: ~/bonusvarsel)
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
FILE="$ROOT/lib/pages/premium_page.dart"
ELITE="bJecN600a8j8f7P8bvcQU06"
PREMIUM="9B65kE28i7f44tbcrLcQU05"

[ -f "$FILE" ] || { echo "FEIL: finner ikke $FILE"; exit 1; }

antall_elite_for_premium=$(grep -c "$ELITE" "$FILE" || true)
if [ "$antall_elite_for_premium" = "0" ]; then
  if grep -q "$PREMIUM" "$FILE"; then echo "OK: $FILE bruker allerede Premium-lenken. Ingenting å endre."; exit 0; fi
  echo "FEIL: fant ingen av lenkene i $FILE. Sjekk filen manuelt."; exit 1
fi

cp "$FILE" "$FILE.bak"
sed -i.tmp "s|https://buy.stripe.com/$ELITE|https://buy.stripe.com/$PREMIUM|g" "$FILE"
rm -f "$FILE.tmp"

echo "Endret $antall_elite_for_premium linje(r) i premium_page.dart"
echo "Sjekk:"
grep -n "buy.stripe.com" "$FILE"
if grep -q "$ELITE" "$FILE"; then echo "FEIL: Elite-lenken finnes fortsatt. Gjenoppretter sikkerhetskopi."; mv "$FILE.bak" "$FILE"; exit 1; fi
rm -f "$FILE.bak"
echo "OK: Premium-knappen peker nå til $PREMIUM (49 kr)."
echo "Neste: flutter build og ny innsending til App Store (1.3.1)."
