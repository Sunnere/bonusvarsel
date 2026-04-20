#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

echo "Backup..."
cp lib/services/paywall_trigger_service.dart lib/services/paywall_trigger_service.dart.bak.$STAMP

# --------------------------------------------------
# UPDATE SERVICE (add click tracking)
# --------------------------------------------------
perl -0777 -pe "
s/class PaywallTriggerService {/class PaywallTriggerService {\n  static const _adClickCountKey = 'paywall_ad_click_count_v1';/g
" -i lib/services/paywall_trigger_service.dart

# Add method: register ad click
perl -0777 -pe "
s/static Future<void> reset\(\) async {/static Future<void> registerAdClick(BuildContext context) async {\n    final prefs = await SharedPreferences.getInstance();\n\n    final count = prefs.getInt(_adClickCountKey) ?? 0;\n    final newCount = count + 1;\n\n    await prefs.setInt(_adClickCountKey, newCount);\n\n    if (newCount >= 3) {\n      await prefs.setInt(_adClickCountKey, 0);\n\n      await showPaywall(\n        context,\n        source: 'momentum_clicks',\n        title: 'Få mer ut av kjøpene dine',\n        subtitle: 'Du er aktiv nå – Premium gir deg bedre bonus før neste klikk.',\n      );\n    }\n  }\n\n  static Future<void> reset() async {/g
" -i lib/services/paywall_trigger_service.dart

# --------------------------------------------------
# PATCH AdSlotCard (track clicks)
# --------------------------------------------------
perl -0777 -pe "
s/await AdService\.instance\.recordClick\(/await AdService.instance.recordClick(/g
" -i lib/widgets/ad_slot.dart

perl -0777 -pe "
s/await _openUrl\(widget\.slot\.link\);/await PaywallTriggerService.registerAdClick(context);\n    await _openUrl(widget.slot.link);/g
" -i lib/widgets/ad_slot.dart

echo
echo "Momentum trigger installert"
echo
echo "Kjør nå:"
echo "flutter analyze"
echo "flutter test"
