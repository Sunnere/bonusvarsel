#!/bin/bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"
BACKUP="${FILE}.bak_951_add_checkout_debug_logs_$(date +%Y%m%d_%H%M%S)"

cp "$FILE" "$BACKUP"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/services/checkout_service.dart")
text = path.read_text()

needle = """  Future<void> setSelection({
    required String plan,
    required String billing,
  }) async {
    _plan = plan;
    _billing = billing;
  }
"""

replacement = """  Future<void> setSelection({
    required String plan,
    required String billing,
  }) async {
    _plan = plan;
    _billing = billing;
    debugPrint('CheckoutService.setSelection: plan=$_plan billing=$_billing partner=$_isPartner effectivePlan=$effectivePlan productId=${selectedProductId()}');
  }
"""

if needle not in text:
    raise SystemExit("Fant ikke setSelection()-blokk. Avbryter.")

text = text.replace(needle, replacement, 1)

needle2 = """  Future<void> setBilling(String value) async {
    _billing = value;
  }
"""

replacement2 = """  Future<void> setBilling(String value) async {
    _billing = value;
    debugPrint('CheckoutService.setBilling: billing=$_billing productId=${selectedProductId()}');
  }
"""

if needle2 not in text:
    raise SystemExit("Fant ikke setBilling()-blokk. Avbryter.")

text = text.replace(needle2, replacement2, 1)

needle3 = """  Future<void> setPartner(bool value) async {
    _isPartner = value;
  }
"""

replacement3 = """  Future<void> setPartner(bool value) async {
    _isPartner = value;
    debugPrint('CheckoutService.setPartner: partner=$_isPartner plan=$_plan billing=$_billing effectivePlan=$effectivePlan productId=${selectedProductId()}');
  }
"""

if needle3 not in text:
    raise SystemExit("Fant ikke setPartner()-blokk. Avbryter.")

text = text.replace(needle3, replacement3, 1)

path.write_text(text)
PY

echo "✅ La inn debug-logging i checkout service"
echo "✅ Backup laget: $BACKUP"
echo
echo "Kjør nå:"
echo "  flutter analyze"
