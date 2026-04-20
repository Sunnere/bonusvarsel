#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
cp "$FILE" "$FILE.bak_821.$(date +%s)"

sed -i '' 's/bool _pushTestExpanded =/final bool _pushTestExpanded =/' "$FILE"

echo "✅ Gjorde _pushTestExpanded final"

flutter analyze
