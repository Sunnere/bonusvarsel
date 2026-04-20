#!/usr/bin/env bash
set -euo pipefail

echo "== Bonusvarsel release checklist run =="

echo
echo "[1/6] flutter analyze"
flutter analyze

echo
echo "[2/6] verifiser launch docs"
test -f docs/launch/release_checklist.md
test -f docs/launch/app_store_text.md
test -f docs/launch/play_store_text.md
test -f docs/launch/privacy_policy.md
echo "✅ launch docs finnes"

echo
echo "[3/6] sjekk at alerts-side finnes"
test -f lib/pages/bonusvarsel_alerts_page.dart
echo "✅ alerts-side finnes"

echo
echo "[4/6] sjekk at Dev Hub gating finnes"
grep -n "_devHubEnabled" lib/pages/bonusvarsel_dev_hub_page.dart >/dev/null
grep -n "ENABLE_DEV_HUB" lib/pages/bonusvarsel_dev_hub_page.dart >/dev/null
echo "✅ Dev Hub gating funnet"

echo
echo "[5/6] sjekk at release-scripts finnes"
test -f scripts/run_prod_like_web.sh
test -f scripts/verify_dev_hub_hidden.sh
test -f scripts/release_snapshot.sh
echo "✅ release-scripts finnes"

echo
echo "[6/6] oppsummering"
echo "✅ Release-basics ser OK ut"
