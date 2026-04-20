#!/bin/bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"
BACKUP="${FILE}.bak_952b_fix_checkout_service_product_id_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"

python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/services/checkout_service.dart")
text = path.read_text()

pattern = re.compile(
    r"""String selectedProductId\(\)\s*\{\s*
    final _planPart = _plan\.toLowerCase\(\);\s*
    final billingPart = _billing == 'yearly' \? 'yearly' : 'monthly';\s*
    return '\$\{_planPart\}\}_\$billingPart';\s*
    \}""",
    re.VERBOSE | re.DOTALL,
)

replacement = """String selectedProductId() {
    final _planPart = _plan.toLowerCase();
    final billingPart = _billing == 'yearly' ? 'yearly' : 'monthly';
    return '\${_planPart}_\$billingPart';
  }"""

new_text, count = pattern.subn(replacement, text, count=1)

if count != 1:
    raise SystemExit("Fant ikke selectedProductId()-blokken med kjent feil. Avbryter.")

path.write_text(new_text)
print("OK")
PY

echo "✅ Fikset selectedProductId() robust"
echo "✅ Backup laget: $BACKUP"
echo
echo "Verifiser med:"
echo "  sed -n '60,95p' lib/services/checkout_service.dart"
echo "  flutter analyze"
