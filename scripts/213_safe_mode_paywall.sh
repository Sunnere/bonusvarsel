#!/usr/bin/env bash
set -euo pipefail

STAMP="$(date +%Y%m%d-%H%M%S)"

FILE="lib/services/paywall_trigger_service.dart"

cp "$FILE" "${FILE}.bak.${STAMP}"
echo "Backup laget: ${FILE}.bak.${STAMP}"

# --------------------------------------------------
# Gjør momentum trigger safe
# --------------------------------------------------
perl -0777 -pe "
s/if \(newCount >= 3\)/if (newCount >= 4)/g
" -i "$FILE"

# --------------------------------------------------
# Legg inn _canShowPaywall() check
# --------------------------------------------------
perl -0777 -pe "
s/await showPaywall\(/final allowed = await _canShowPaywall();\n      if (!allowed) return;\n\n      await showPaywall(/g
" -i "$FILE"

echo
echo "Safe mode aktivert"
echo
echo "Kjør:"
echo "flutter analyze"
echo "flutter test"
