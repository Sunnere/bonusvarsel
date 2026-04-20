#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_782_inspect_real_app_state_sources"
echo

echo "==> 1) Søker etter valgt kort / card state"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nEi \
  "selectedCard|selected_card|cardId|card_id|rateFor\(|CardCatalog|setSelectedCard|getSelectedCard|selected card" || true

echo
echo "==> 2) Søker etter premium / elite / tier state"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nEi \
  "isPremium|isElite|premium|elite|tier|subscription|billingCycle|premium_active|has_premium|has_elite|PremiumService" || true

echo
echo "==> 3) Søker etter favoritter"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nEi \
  "favorite|favourite|favorites|favourites|favorite_store|favoriteStore|favoriteIds|starred|bookmarked" || true

echo
echo "==> 4) Søker etter shopping offers / valgt offer"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nEi \
  "offers|offer|currentSelection|selectedOffer|selected_offer|shop_offer|eb_item|feed_item|rateText|rate" || true

echo
echo "==> 5) Søker etter SharedPreferences/state-kilder"
find lib -type f -name "*.dart" -print0 | xargs -0 grep -nEi \
  "SharedPreferences|getInstance\(|prefs\.|setString|getString|getStringList|setStringList|getBool|setBool|getInt|setInt" || true

echo
echo "✅ Ferdig"
echo
echo "Lim inn outputen her."
echo "Da lager jeg en målrettet wiring-cat som bruker ekte app-state, ikke fallback-gjetting."
