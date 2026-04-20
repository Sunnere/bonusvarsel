#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_802_diagnose_offers_feed_integration"

echo
echo "==> 1) Vis nye filer"
ls -la lib/models/offer_feed_item.dart || true
ls -la lib/models/offers_feed_response.dart || true
ls -la lib/services/offers_feed_repository.dart || true
ls -la lib/services/offers_refresh_service.dart || true

echo
echo "==> 2) Sjekk api_service.dart rundt getOffersFeed"
grep -n "getOffersFeed" lib/services/api_service.dart || true
sed -n '1,260p' lib/services/api_service.dart

echo
echo "==> 3) Kjør fokusert analyze på nye filer"
flutter analyze \
  lib/models/offer_feed_item.dart \
  lib/models/offers_feed_response.dart \
  lib/services/offers_feed_repository.dart \
  lib/services/offers_refresh_service.dart \
  lib/services/api_service.dart || true

echo
echo "==> 4) Kjør full analyze til fil"
flutter analyze > /tmp/bonusvarsel_analyze.txt 2>&1 || true
echo "Analyze lagret i /tmp/bonusvarsel_analyze.txt"

echo
echo "==> 5) Vis første 120 linjer fra analyze"
sed -n '1,120p' /tmp/bonusvarsel_analyze.txt

echo
echo "==> 6) Vis siste 80 linjer fra analyze"
tail -80 /tmp/bonusvarsel_analyze.txt

echo
echo "✅ Ferdig"
echo "Lim inn outputen fra steg 3, og gjerne første del av steg 5."
