#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "== Bonusvarsel store prep =="

echo
echo "[1/5] Sjekker launch docs"
test -f docs/launch/app_store_text.md
test -f docs/launch/play_store_text.md
test -f docs/launch/privacy_policy.md
echo "✅ launch docs finnes"

echo
echo "[2/5] Sjekker store prep docs"
test -f docs/launch/screenshots_checklist.md
test -f docs/launch/store_submission_checklist.md
test -f docs/launch/contact_and_links.md
echo "✅ store prep docs finnes"

echo
echo "[3/5] Sjekker release scripts"
test -f scripts/release_checklist_run.sh
test -f scripts/run_prod_like_web.sh
test -f scripts/verify_dev_hub_hidden.sh
echo "✅ release scripts finnes"

echo
echo "[4/5] Kjører flutter analyze"
flutter analyze

echo
echo "[5/5] Oppsummering"
echo "✅ Store prep-basis er på plass"
echo "Neste: fyll inn kontaktinfo, ta screenshots, og kjør prod-lignende test"
