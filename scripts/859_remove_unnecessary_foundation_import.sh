#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/bonusvarsel_dev_hub_page.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_859.$(date +%s)"
echo "✅ Backup laget: $FILE"

# fjern kun foundation-importen
grep -v "package:flutter/foundation.dart" "$FILE" > "$FILE.tmp"
mv "$FILE.tmp" "$FILE"

flutter analyze
echo "✅ 859 ferdig (fjernet unødvendig import)"
