#!/bin/bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"
BACKUP="${FILE}.bak_962_cleanup_checkout_service_logs_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/services/checkout_service.dart")
text = path.read_text()

text = text.replace("    final _planPart = _plan.toLowerCase();\n", "    final planPart = _plan.toLowerCase();\n")
text = text.replace("    return '${_planPart}_$billingPart';\n", "    return '${planPart}_$billingPart';\n")

path.write_text(text)
print("OK")
PY

echo "✅ Ryddet selectedProductId()"
echo "✅ Backup laget: $BACKUP"
