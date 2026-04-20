#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/checkout_page.dart"

if [ ! -f "$FILE" ]; then
  echo "❌ Fant ikke $FILE"
  exit 1
fi

cp "$FILE" "${FILE}.bak_706"

python3 - <<'PY'
from pathlib import Path

path = Path("lib/pages/checkout_page.dart")
text = path.read_text()
original = text

if "../services/entitlement_service.dart" not in text:
    text = text.replace(
        "import '../services/checkout_service.dart';",
        "import '../services/checkout_service.dart';\nimport '../services/entitlement_service.dart';"
    )

if "initState()" not in text:
    text = text.replace(
        "class _CheckoutPageState extends State<CheckoutPage> {\n  String billing = CheckoutService.instance.billing;\n",
        """class _CheckoutPageState extends State<CheckoutPage> {
  String billing = CheckoutService.instance.billing;

  @override
  void initState() {
    super.initState();
    CheckoutService.instance.init();
  }
"""
    )

old_button = """                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Neste steg: betaling')),
                  );
                },"""

new_button = """                onPressed: () async {
                  await CheckoutService.instance.setBilling(billing);
                  await CheckoutService.instance.buySelected();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kjøpsflyt startet')),
                  );
                },"""

if old_button in text:
    text = text.replace(old_button, new_button, 1)

spacer = "            const Spacer(),"
restore_block = """            const Spacer(),

            TextButton(
              onPressed: () async {
                await CheckoutService.instance.restorePurchases();
                if (!mounted) return;
                final plan = EntitlementService.instance.plan;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore kjørt. Nåværende plan: $plan')),
                );
              },
              child: const Text('Gjenopprett kjøp'),
            ),"""
if spacer in text and "Gjenopprett kjøp" not in text:
    text = text.replace(spacer, restore_block, 1)

if text == original:
    print("⚠️ Ingen endring gjort.")
else:
    path.write_text(text)
    print("✅ checkout_page.dart oppdatert")
PY

echo
echo "==> flutter analyze"
flutter analyze || true
