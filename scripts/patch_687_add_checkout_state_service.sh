#!/usr/bin/env bash
set -euo pipefail

SERVICE_FILE="lib/services/checkout_service.dart"
PAGE_FILE="lib/pages/premium_page.dart"

mkdir -p lib/services

# --- Backup ---
[ -f "$PAGE_FILE" ] && cp "$PAGE_FILE" "${PAGE_FILE}.bak_687_checkout_state"

echo "✅ Lager CheckoutService..."

cat > "$SERVICE_FILE" <<'DART'
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutService {
  CheckoutService._();
  static final CheckoutService instance = CheckoutService._();

  static const _keyPlan = 'checkout_plan';
  static const _keyBilling = 'checkout_billing';

  String _plan = 'Premium';
  String _billing = 'monthly';

  String get plan => _plan;
  String get billing => _billing;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _plan = prefs.getString(_keyPlan) ?? 'Premium';
    _billing = prefs.getString(_keyBilling) ?? 'monthly';
  }

  Future<void> setSelection({
    required String plan,
    required String billing,
  }) async {
    _plan = plan;
    _billing = billing;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPlan, plan);
    await prefs.setString(_keyBilling, billing);
  }

  Map<String, dynamic> toPayload() {
    return {
      'plan': _plan.toLowerCase(),       // premium / elite
      'billing': _billing,               // monthly / yearly
    };
  }
}
DART

echo "✅ Patcher PremiumPage..."

python3 - <<'PY'
from pathlib import Path
import re

path = Path("lib/pages/premium_page.dart")
text = path.read_text()
changed = False

# 1. import service
if "checkout_service.dart" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\nimport '../services/checkout_service.dart';"
    )
    changed = True

# 2. init load() i initState
if "initState()" in text and "CheckoutService.instance.load()" not in text:
    text = re.sub(
        r"(class _PremiumPageState extends State<PremiumPage> \{)",
        r"\1\n\n  @override\n  void initState() {\n    super.initState();\n    CheckoutService.instance.load();\n  }\n",
        text
    )
    changed = True

# 3. oppdater _checkout()
pattern = r"void _checkout\(String plan\) \{.*?\}"
replacement = """
  void _checkout(String plan) async {
    await CheckoutService.instance.setSelection(
      plan: plan,
      billing: _billingCycle,
    );

    final payload = CheckoutService.instance.toPayload();

    // TODO: kobles til Stripe / IAP senere
    print('Checkout payload: $payload');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Valgt: ${payload['plan']} (${payload['billing']})',
        ),
      ),
    );
  }
"""
new_text, count = re.subn(pattern, replacement, text, flags=re.DOTALL)

if count:
    text = new_text
    changed = True

if changed:
    path.write_text(text)
    print("✅ PremiumPage koblet til CheckoutService")
else:
    print("⚠️ Fant ikke _checkout pattern – ingen endring")
PY

echo
echo "==> flutter analyze"
flutter analyze || true

echo
echo "Ferdig."
echo "Test:"
echo "  flutter run -d 00008110-001138643E60401E"
echo "Trykk på Premium/Elite og se payload i console."
