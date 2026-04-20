#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_761_wire_paywall_to_real_purchase_flow"

if [ ! -f "lib/paywall/paywall_sheet.dart" ]; then
  echo "❌ Mangler lib/paywall/paywall_sheet.dart"
  echo "Kjør først:"
  echo "  bash scripts/patch_755_create_paywall_design_and_copy.sh"
  exit 1
fi

mkdir -p lib/paywall

cat > lib/paywall/paywall_real_purchase_flow.dart <<'DART'
import 'package:flutter/material.dart';

class PaywallRealPurchaseFlow {
  static const String premiumRouteName = '/premium';

  static Future<void> startPurchaseFlow(
    BuildContext context, {
    required String planId,
  }) async {
    final args = <String, dynamic>{
      'source': 'paywall',
      'action': 'purchase',
      'planId': planId,
      'billingCycle': planId,
    };

    final navigator = Navigator.of(context);

    try {
      await navigator.pushNamed(premiumRouteName, arguments: args);
      return;
    } catch (_) {
      // fallback below
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fant ikke /premium-route. Koble Premium-siden til named route for full kjøpsflyt.',
        ),
      ),
    );
  }

  static Future<void> restorePurchases(BuildContext context) async {
    final args = <String, dynamic>{
      'source': 'paywall',
      'action': 'restore',
    };

    final navigator = Navigator.of(context);

    try {
      await navigator.pushNamed(premiumRouteName, arguments: args);
      return;
    } catch (_) {
      // fallback below
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Fant ikke /premium-route. Koble Premium-siden til named route for gjenoppretting.',
        ),
      ),
    );
  }
}
DART

python3 <<'PY'
from pathlib import Path
import re
from datetime import datetime

targets = [
    Path("lib/paywall/paywall_content.dart"),
    Path("lib/paywall/paywall_preview_page.dart"),
]

for path in targets:
    if path.exists():
        backup = path.with_suffix(path.suffix + f".bak_761_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
        backup.write_text(path.read_text())

# 1) Update CTA text
content_path = Path("lib/paywall/paywall_content.dart")
content = content_path.read_text()

content = content.replace(
    "static const String cta = 'Start Premium';",
    "static const String cta = 'Fortsett til betaling';",
)

content_path.write_text(content)

# 2) Wire preview page to real purchase flow
preview_path = Path("lib/paywall/paywall_preview_page.dart")
preview = preview_path.read_text()

if "paywall_real_purchase_flow.dart" not in preview:
    imports = list(re.finditer(r"^import .+?;\n", preview, flags=re.MULTILINE))
    if imports:
      last = imports[-1]
      preview = preview[:last.end()] + "import 'paywall_real_purchase_flow.dart';\n" + preview[last.end():]
    else:
      preview = "import 'paywall_real_purchase_flow.dart';\n" + preview

# Replace old SnackBar callbacks if present
preview = re.sub(
    r"onStartPlan:\s*\(planId\)\s*\{.*?^\s*\},",
    "onStartPlan: (planId) => PaywallRealPurchaseFlow.startPurchaseFlow(\n"
    "        context,\n"
    "        planId: planId,\n"
    "      ),",
    preview,
    flags=re.DOTALL | re.MULTILINE,
)

preview = re.sub(
    r"onRestorePurchases:\s*\(\)\s*\{.*?^\s*\},",
    "onRestorePurchases: () => PaywallRealPurchaseFlow.restorePurchases(context),",
    preview,
    flags=re.DOTALL | re.MULTILINE,
)

preview_path.write_text(preview)

# 3) Report
report = Path("lib/paywall/_patch_761_report.txt")
report.write_text(
    "✅ Oppdatert paywall CTA til 'Fortsett til betaling'\n"
    "✅ Laget lib/paywall/paywall_real_purchase_flow.dart\n"
    "✅ Wiret paywall_preview_page.dart til /premium named route\n"
)
print(report.read_text())
PY

echo
echo "✅ Ferdig"
echo
echo "Neste:"
echo "1) Sørg for at appen faktisk har named route '/premium'"
echo "2) flutter analyze"
echo "3) test paywall -> Fortsett til betaling"
echo
echo "Hvis '/premium' ikke finnes ennå, legg den til i appens route-map eller onGenerateRoute."
