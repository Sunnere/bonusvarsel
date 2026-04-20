#!/usr/bin/env bash
set -e

FILE="lib/services/checkout_service.dart"

cp "$FILE" "$FILE.bak_703"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/services/checkout_service.dart")
text = path.read_text()

if "purchaseStream" not in text:
    insert = """
  void initListener() {
    _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased) {
          // unlock
          // ignore: avoid_print
          print('Kjøpt: ${purchase.productID}');
        }
      }
    });
  }
"""
    text = text.replace("CheckoutService._();", "CheckoutService._() {\n    initListener();\n  }")
    text = text.replace("}", insert + "\n}", 1)

path.write_text(text)
print("✅ Listener lagt til")
PY
