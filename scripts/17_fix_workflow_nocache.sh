#!/bin/bash
set -e
TARGET=".github/workflows/bonusvarsel.yml"
cp "$TARGET" "$TARGET.bak_$(date +%Y%m%d_%H%M%S)"

# Legg til NO_CACHE=1 i collector-kommandoen
sed -i '' 's|run: CHANNEL=SAS LANGUAGE=nb COUNTRY=no PER_PAGE=100 node scripts/collect-loyaltykey.mjs|run: NO_CACHE=1 CHANNEL=SAS LANGUAGE=nb COUNTRY=no PER_PAGE=100 node scripts/collect-loyaltykey.mjs|' "$TARGET"

echo "✅ NO_CACHE=1 lagt til i workflow"
grep "collect-loyaltykey" "$TARGET"
