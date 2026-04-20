#!/usr/bin/env bash
set -euo pipefail

FILE="lib/services/checkout_service.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_708_add_checkout_debug_logs"
echo "✅ Backup laget: ${FILE}.bak_708_add_checkout_debug_logs"

python3 - <<'PY'
from pathlib import Path
path = Path("lib/services/checkout_service.dart")
text = path.read_text()
orig = text

repls = [
    (
        "await EntitlementService.instance.load();",
        """await EntitlementService.instance.load();
    debugPrint('CheckoutService.init: entitlement plan=${EntitlementService.instance.plan} productId=${EntitlementService.instance.productId}');"""
    ),
    (
        "debugPrint('IAP unavailable on this device/account.');",
        "debugPrint('IAP unavailable on this device/account. isAvailable=false');"
    ),
    (
        "products = response.productDetails;",
        """products = response.productDetails;
    debugPrint('IAP loaded products count=${products.length}');
    for (final p in products) {
      debugPrint('IAP product loaded: id=${p.id} title=${p.title} price=${p.price}');
    }"""
    ),
    (
        "final productId = selectedProductId();",
        """final productId = selectedProductId();
    debugPrint('buySelected: plan=$_plan billing=$_billing partner=$_isPartner effectivePlan=$effectivePlan productId=$productId');"""
    ),
    (
        "if (product == null) {",
        """debugPrint('buy: requested productId=$productId');
    if (product == null) {
      debugPrint('buy: available products=${products.map((p) => p.id).toList()}');"""
    ),
    (
        "final purchaseParam = PurchaseParam(productDetails: product);",
        """debugPrint('buy: found product id=${product.id} title=${product.title} price=${product.price}');
    final purchaseParam = PurchaseParam(productDetails: product);"""
    ),
    (
        "await _iap.buyNonConsumable(purchaseParam: purchaseParam);",
        """debugPrint('buy: calling buyNonConsumable...');
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    debugPrint('buy: buyNonConsumable returned without throw');"""
    ),
    (
        "await _iap.restorePurchases();",
        """debugPrint('restorePurchases: calling restorePurchases()');
    await _iap.restorePurchases();
    debugPrint('restorePurchases: returned without throw');"""
    ),
]

for a,b in repls:
    if a in text:
        text = text.replace(a,b,1)

if text == orig:
    print("⚠️ Ingen endringer gjort.")
else:
    path.write_text(text)
    print("✅ checkout_service.dart oppdatert med debug-logging")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
