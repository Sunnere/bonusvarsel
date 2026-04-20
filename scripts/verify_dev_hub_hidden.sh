#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"

echo "== Verifiserer at Dev Hub er gated i prod =="
grep -n "_devHubEnabled" "$FILE"
grep -n "ENABLE_DEV_HUB" "$FILE"
grep -n "Dev Hub er deaktivert i denne byggen." "$FILE"

echo
echo "✅ Kode for å skjule Dev Hub i prod finnes"
echo "Kjør deretter scripts/run_prod_like_web.sh og bekreft i UI"
