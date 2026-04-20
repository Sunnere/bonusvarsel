#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

# Backup
cp lib/widgets/paywall_scroll_wrapper.dart lib/widgets/paywall_scroll_wrapper.dart.bak.$STAMP
cp lib/widgets/premium_paywall_sheet.dart lib/widgets/premium_paywall_sheet.dart.bak.$STAMP

echo "Backup laget"

# Fix async context warning
perl -0777 -pe "
s/await PaywallTriggerService\.markScrollDepthSeen\(\);\n\n\s+await PaywallTriggerService\.showPaywall\(/if (!mounted) return;\n\n          await PaywallTriggerService.markScrollDepthSeen();\n\n          if (!mounted) return;\n\n          await PaywallTriggerService.showPaywall(/g
" -i lib/widgets/paywall_scroll_wrapper.dart

# Fjern unused 'card'
perl -0777 -pe "
s/const card = Color\(0xFF152742\);\n//g
" -i lib/widgets/premium_paywall_sheet.dart

echo "Cleanup ferdig"

echo
echo "Kjør:"
echo "flutter analyze"
echo "flutter test"
