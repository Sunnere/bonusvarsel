#!/bin/bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"
BACKUP="${FILE}.bak_950_fix_checkout_product_id_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/services/checkout_service.dart")
text = path.read_text()

old = "    return '\${_planPart}}_\$billingPart';\n"
new = "    return '\${_planPart}_\$billingPart';\n"

if old not in text:
    raise SystemExit("Fant ikke forventet linje for selectedProductId(). Avbryter.")

text = text.replace(old, new, 1)
path.write_text(text)
PY

echo "✅ Fikset selectedProductId()"
echo "✅ Backup laget: $BACKUP"
echo
echo "Kjør nå:"
echo "  flutter analyze"
