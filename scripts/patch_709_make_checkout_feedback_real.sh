#!/usr/bin/env bash
set -euo pipefail

FILE1="lib/services/checkout_service.dart"
FILE2="lib/pages/checkout_page.dart"

if [ ! -f "$FILE1" ]; then
  echo "❌ Fant ikke $FILE1"
  exit 1
fi

if [ ! -f "$FILE2" ]; then
  echo "❌ Fant ikke $FILE2"
  exit 1
fi

cp "$FILE1" "${FILE1}.bak_709_make_checkout_feedback_real"
cp "$FILE2" "${FILE2}.bak_709_make_checkout_feedback_real"
echo "✅ Backup laget"

python3 - <<'PY'
from pathlib import Path

svc = Path("lib/services/checkout_service.dart")
page = Path("lib/pages/checkout_page.dart")

svc_text = svc.read_text()
page_text = page.read_text()

orig_svc = svc_text
orig_page = page_text

# checkout_service.dart
if "Future<String> buySelectedVerbose()" not in svc_text:
    marker = "  Future<void> buySelected() async {"
    insert = """
  Future<String> buySelectedVerbose() async {
    final productId = selectedProductId();
    debugPrint('buySelectedVerbose: selected productId=$productId');

    if (products.isEmpty) {
      debugPrint('buySelectedVerbose: products empty, reloading...');
      await loadProducts();
    }

    final product = getProduct(productId);
    if (product == null) {
      final ids = products.map((p) => p.id).toList();
      debugPrint('buySelectedVerbose: product not found. loaded=$ids');
      return 'Produkt ikke tilgjengelig enda i App Store / TestFlight.';
    }

    try {
      debugPrint('buySelectedVerbose: calling buy for $productId');
      await buy(productId);
      return 'Apple-kjøpsdialog skal vises nå.';
    } catch (e) {
      debugPrint('buySelectedVerbose: exception=$e');
      return 'Kjøp feilet: $e';
    }
  }

"""
    svc_text = svc_text.replace(marker, insert + marker, 1)

# checkout_page.dart
old = """                onPressed: () async {
                  await CheckoutService.instance.setBilling(billing);
                  await CheckoutService.instance.buySelected();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kjøpsflyt startet')),
                  );
                },"""

new = """                onPressed: () async {
                  await CheckoutService.instance.setBilling(billing);
                  final msg = await CheckoutService.instance.buySelectedVerbose();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                },"""

if old in page_text:
    page_text = page_text.replace(old, new, 1)

if svc_text != orig_svc:
    svc.write_text(svc_text)
    print("✅ checkout_service.dart oppdatert")
else:
    print("ℹ️ checkout_service.dart: ingen endring eller patch finnes allerede")

if page_text != orig_page:
    page.write_text(page_text)
    print("✅ checkout_page.dart oppdatert")
else:
    print("ℹ️ checkout_page.dart: ingen endring eller patch finnes allerede")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
