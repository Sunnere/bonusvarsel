#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

echo "==> Kandidater for annonse"
grep -n "AdSlotCard\|placement:\|Annonse\|slot:" "$FILE" || true

echo
echo "==> Kandidater for Premium / Elite / typisk gevinst / mål"
grep -n "Premium\|Elite\|typisk gevinst\|Typisk gevinst\|mål\|Mål" "$FILE" || true

echo
echo "==> Utdrag rundt første AdSlotCard"
AD_LINE="$(grep -n "AdSlotCard" "$FILE" | head -n1 | cut -d: -f1 || true)"
if [ -n "${AD_LINE:-}" ]; then
  START=$((AD_LINE>35 ? AD_LINE-35 : 1))
  END=$((AD_LINE+45))
  sed -n "${START},${END}p" "$FILE"
else
  echo "Fant ingen AdSlotCard-linje"
fi

echo
echo "==> Utdrag rundt 'typisk gevinst' eller 'mål'"
TIER_LINE="$(grep -ni "typisk gevinst\|mål" "$FILE" | head -n1 | cut -d: -f1 || true)"
if [ -n "${TIER_LINE:-}" ]; then
  START=$((TIER_LINE>40 ? TIER_LINE-40 : 1))
  END=$((TIER_LINE+60))
  sed -n "${START},${END}p" "$FILE"
else
  echo "Fant ikke 'typisk gevinst' eller 'mål' direkte i filen"
  echo
  echo "==> Fallback: utdrag rundt første Premium/Elite-treff"
  FALLBACK_LINE="$(grep -n "Premium\|Elite" "$FILE" | head -n1 | cut -d: -f1 || true)"
  if [ -n "${FALLBACK_LINE:-}" ]; then
    START=$((FALLBACK_LINE>40 ? FALLBACK_LINE-40 : 1))
    END=$((FALLBACK_LINE+80))
    sed -n "${START},${END}p" "$FILE"
  else
    echo "Fant heller ikke Premium/Elite direkte i filen"
  fi
fi
