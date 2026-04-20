#!/usr/bin/env bash
set -euo pipefail

FILE="lib/pages/premium_page.dart"

cp "$FILE" "${FILE}.bak_690_force_add_billing_cycle"

awk '
BEGIN { inserted=0 }

/class _PremiumPageState extends State<PremiumPage>/ {
  print $0
  if (!inserted) {
    print "  String _billingCycle = '\''monthly'\'';"
    inserted=1
  }
  next
}

{ print }

END {
  if (!inserted) {
    print "⚠️ Klarte ikke å sette _billingCycle"
  }
}
' "$FILE" > "${FILE}.tmp"

mv "${FILE}.tmp" "$FILE"

echo "✅ _billingCycle lagt inn"
