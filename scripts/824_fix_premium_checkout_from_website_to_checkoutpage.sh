#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP="${FILE}.bak_${STAMP}_824"

echo "==> 824_fix_premium_checkout_from_website_to_checkoutpage"
cp "$FILE" "$BACKUP"
echo "Backup: $BACKUP"

python3 - <<'PY'
from pathlib import Path
import sys

path = Path("lib/pages/premium_page.dart")
src = path.read_text(encoding="utf-8")
orig = src

# 1) Sørg for at checkout_page.dart er importert
if "import 'checkout_page.dart';" not in src:
    needle = "import '../services/checkout_service.dart';\n"
    if needle not in src:
        print("❌ Fant ikke import for checkout_service.dart")
        sys.exit(1)
    src = src.replace(
        needle,
        needle + "import 'checkout_page.dart';\n",
        1,
    )

# 2) Bytt _checkout() fra nettside til intern checkout
old = """  void _checkout(String plan) async {
    await CheckoutService.instance.setSelection(
      plan: plan,
      billing: _billingCycle,
    );

    final payload = CheckoutService.instance.toPayload();

    // TODO: kobles til Stripe / IAP senere
    debugPrint('Checkout payload: $payload');

    if (!mounted) return;

    
await launchUrl(
  Uri.parse(_subscriptionsUrl),
  mode: LaunchMode.externalApplication,
);

  }
"""

new = """  void _checkout(String plan) async {
    if (plan == 'Gratis') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gratis krever ingen betaling.')),
      );
      return;
    }

    await CheckoutService.instance.setSelection(
      plan: plan,
      billing: _billingCycle,
    );

    final payload = CheckoutService.instance.toPayload();

    // TODO: kobles til ekte Apple IAP / StoreKit
    debugPrint('Checkout payload: $payload');

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }
"""

if old not in src:
    print("❌ Fant ikke eksakt _checkout()-blokk")
    print("Kjør og send:")
    print("  sed -n '40,95p' lib/pages/premium_page.dart")
    sys.exit(1)

src = src.replace(old, new, 1)

if src == orig:
    print("❌ Ingen endringer ble gjort")
    sys.exit(1)

path.write_text(src, encoding="utf-8")
print("✅ _checkout() er nå koblet til CheckoutPage")
PY

echo
echo "Kjør nå:"
echo "  flutter analyze"
echo "  flutter run -d macos"
