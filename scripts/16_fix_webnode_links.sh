#!/usr/bin/env bash
# 16_fix_webnode_links.sh
# Sjekker og reparerer lenkene i webnode/forside.html og webnode/navbar.html.
# Bytter uløste variabler ($APPSTORE_URL osv.) og feil App Store-ID med riktige verdier.
# Bruk: bash scripts/16_fix_webnode_links.sh [rot-mappe]   (default: ~/bonusvarsel)
set -euo pipefail

ROOT="${1:-$HOME/bonusvarsel}"
DIR="$ROOT/webnode"
APPSTORE_URL="https://apps.apple.com/no/app/bonusvarsel/id6761297259"
SHOP_URL="https://bonusshop.no"
CONTACT_EMAIL="support@bonusvarsel.no"
OLD_ID="id6740671773"
NEW_ID="id6761297259"

for f in forside.html navbar.html; do
  p="$DIR/$f"
  [ -f "$p" ] || { echo "FEIL: finner ikke $p. Kjør først: bash scripts/15_build_webnode_forside.sh"; exit 1; }
  before=$(grep -c '\$APPSTORE_URL\|\$SHOP_URL\|\$CONTACT_EMAIL\|\$PRIVACY_URL' "$p" || true)
  sed -i.bak \
    -e "s|\$APPSTORE_URL|$APPSTORE_URL|g" \
    -e "s|\$SHOP_URL|$SHOP_URL|g" \
    -e "s|\$CONTACT_EMAIL|$CONTACT_EMAIL|g" \
    -e "s|$OLD_ID|$NEW_ID|g" "$p"
  rm -f "$p.bak"
  left=$(grep -c '\$[A-Z_]\{4,\}' "$p" || true)
  old=$(grep -c "$OLD_ID" "$p" || true)
  apple=$(grep -o "apps.apple.com/no/app/bonusvarsel/$NEW_ID" "$p" | wc -l | tr -d ' ')
  echo "$f: variabellinjer fikset=$before, rester=$left, gammel ID=$old, riktige App Store-lenker=$apple"
  if [ "$left" != "0" ] || [ "$old" != "0" ]; then echo "FEIL: $f har fortsatt feil"; exit 1; fi
done
echo "OK: begge filer er rene. Lim dem inn i Webnode på nytt (forside.html + navbar.html) og publiser."
