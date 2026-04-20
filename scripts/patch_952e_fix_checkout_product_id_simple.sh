#!/bin/bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"
BACKUP="${FILE}.bak_952e_fix_checkout_product_id_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"

# erstatt kun }_ -> _
perl -0777 -pe "s/\\}\\_/_/g" "$FILE" > "$FILE.tmp"
mv "$FILE.tmp" "$FILE"

echo "✅ Fjernet feil '}' i productId"
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser:"
echo "  grep -n 'selectedProductId' -n $FILE"
echo "  sed -n '110,130p' $FILE"
echo "  flutter analyze"
