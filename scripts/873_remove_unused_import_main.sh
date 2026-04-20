#!/usr/bin/env bash
set -euo pipefail

FILE="lib/main.dart"
[[ -f "$FILE" ]] || { echo "❌ Fant ikke $FILE"; exit 1; }

cp "$FILE" "$FILE.bak_873.$(date +%s)"
echo "✅ Backup laget"

# fjern kun eb_shopping importen
grep -v "eb_shopping_page.dart" "$FILE" > "$FILE.tmp"
mv "$FILE.tmp" "$FILE"

flutter analyze
echo "✅ 873 ferdig (ryddet unused import)"
