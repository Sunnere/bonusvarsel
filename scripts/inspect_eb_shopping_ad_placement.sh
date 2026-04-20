#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "Fant ikke $FILE"
  echo "Kjør:"
  echo "find lib -iname '*shopping*' -o -iname '*eb*'"
  exit 1
fi

echo "==> Søker etter annonsen"
grep -n "AdSlotCard\|placement:\|Annonse\|ad slot\|ad_" "$FILE" || true

echo
echo "==> Søker etter nivåseksjon"
grep -n "Gratis\|Premium\|Elite\|typisk gevinst\|mål\|nivå" "$FILE" || true

echo
echo "==> Søker etter teller / butikkliste"
grep -n "Viser \|itemCount:\|ListView\|filteredStores\|stores.length" "$FILE" || true

echo
echo "==> Ferdig"
