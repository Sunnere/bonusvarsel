#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_785_verify_recommendation_wiring_state"

echo
echo "==> Widget-fil"
ls -la lib/widgets/best_recommendation_card.dart || true

echo
echo "==> Sjekker recommendation-widget i eb_shopping_page.dart"
grep -n "SmartBestRecommendationCard\|BestRecommendationCard" lib/pages/eb_shopping_page.dart || true

echo
echo "==> Sjekker selection-state"
grep -n "_currentRecommendationSelection" lib/pages/eb_shopping_page.dart || true

echo
echo "==> Sjekker ekte wiring-kilder"
grep -n "futureOffers: _futureShops\|amountNok:\|currentSelection:" lib/pages/eb_shopping_page.dart || true

echo
echo "✅ Ferdig"
