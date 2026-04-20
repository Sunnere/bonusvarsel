#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> patch_768_finish_real_purchase_flow_and_named_route"

PAYWALL_FLOW="lib/paywall/paywall_real_purchase_flow.dart"
MAIN_FILE="lib/main.dart"

if [ ! -f "$PAYWALL_FLOW" ]; then
  echo "❌ Fant ikke $PAYWALL_FLOW"
  exit 1
fi

if [ ! -f "$MAIN_FILE" ]; then
  echo "❌ Fant ikke $MAIN_FILE"
  exit 1
fi

cp "$PAYWALL_FLOW" "$PAYWALL_FLOW.bak_768_$(date +%Y%m%d_%H%M%S)"
cp "$MAIN_FILE" "$MAIN_FILE.bak_768_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup laget"

cat > "$PAYWALL_FLOW" <<'DART'
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

    final localNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final route = ModalRoute.of(context);

    // Hvis paywall ligger i popup/dialog/bottomsheet, lukk den først.
    if (route is PopupRoute && localNavigator.canPop()) {
      localNavigator.pop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    try {
      await rootNavigator.pushNamed(premiumRouteName, arguments: args);
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fant ikke /premium-route. Koble Premium-siden til named route.',
          ),
        ),
      );
    }
  }

  static Future<void> restorePurchases(BuildContext context) async {
    final args = <String, dynamic>{
      'source': 'paywall',
      'action': 'restore',
    };

    final localNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final route = ModalRoute.of(context);

    if (route is PopupRoute && localNavigator.canPop()) {
      localNavigator.pop();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }

    try {
      await rootNavigator.pushNamed(premiumRouteName, arguments: args);
      return;
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fant ikke /premium-route. Koble Premium-siden til named route.',
          ),
        ),
      );
    }
  }
}
DART

python3 <<'PY'
from pathlib import Path
import re

path = Path("lib/main.dart")
text = path.read_text()
report = []

premium_import = "import 'package:bonusvarsel/pages/premium_page.dart';"
if premium_import not in text:
    imports = list(re.finditer(r"^import .+?;\n", text, flags=re.MULTILINE))
    if imports:
        last = imports[-1]
        text = text[:last.end()] + premium_import + "\n" + text[last.end():]
    else:
        text = premium_import + "\n" + text
    report.append("la til premium_page-import")
else:
    report.append("premium_page-import finnes allerede")

if re.search(r"['\"]/premium['\"]\s*:", text):
    report.append("'/premium' route finnes allerede")
else:
    routes_match = re.search(r"routes\s*:\s*\{", text)
    if routes_match:
        insert_at = routes_match.end()
        entry = "\n        '/premium': (_) => const PremiumPage(),"
        text = text[:insert_at] + entry + text[insert_at:]
        report.append("la til '/premium' i eksisterende routes-map")
    else:
        material_app_match = re.search(r"MaterialApp\s*\(", text)
        if not material_app_match:
            raise SystemExit("❌ Fant ikke MaterialApp(")
        insert_at = material_app_match.end()
        snippet = """
      routes: {
        '/premium': (_) => const PremiumPage(),
      },
"""
        text = text[:insert_at] + snippet + text[insert_at:]
        report.append("la til ny routes-map med '/premium'")

path.write_text(text)
Path("lib/paywall/_patch_768_report.txt").write_text("\n".join(report) + "\n")
print("\n".join(report))
PY

echo
echo "==> Rapport"
cat lib/paywall/_patch_768_report.txt || true

echo
echo "✅ Ferdig"
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) test Fortsett til betaling"
echo "3) sjekk at Premium åpner OVER popupen"
