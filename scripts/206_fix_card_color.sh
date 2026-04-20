#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

cp lib/widgets/premium_paywall_sheet.dart lib/widgets/premium_paywall_sheet.dart.bak.$STAMP
echo "Backup laget"

# Legg tilbake card konstant riktig sted (øverst i widget)
perl -0777 -pe "
s/class PremiumPaywallSheet extends StatelessWidget {/class PremiumPaywallSheet extends StatelessWidget {\n  static const Color card = Color(0xFF152742);/g
" -i lib/widgets/premium_paywall_sheet.dart

echo "Fixed card constant"

echo
echo "Kjør nå:"
echo "flutter analyze"
echo "flutter test"
