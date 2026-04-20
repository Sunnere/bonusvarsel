#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/eb_shopping_page.dart"

cp "$FILE" "$FILE.bak_882.$(date +%s)"
echo "✅ Backup laget"

# Fjern linjer som inneholder UpgradeCtaButton
grep -v "_UpgradeCtaButton" "$FILE" > "$FILE.tmp"
mv "$FILE.tmp" "$FILE"

flutter analyze
echo "✅ Oppgrader CTA fjernet"
