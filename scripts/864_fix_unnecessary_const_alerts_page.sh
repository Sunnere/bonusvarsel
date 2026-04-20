#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_alerts_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_864.$(date +%s)"
echo "✅ Backup laget: $FILE"

# fjern const kun på linje 236 (der warning er)
sed -i '' '236s/const //' "$FILE"

flutter analyze
echo "✅ 864 ferdig (fjernet unødvendig const)"
