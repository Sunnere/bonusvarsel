#!/usr/bin/env bash
set -euo pipefail

echo "== Fikser Timer import =="
SHOP="lib/pages/eb_shopping_page.dart"
cp "$SHOP" "$SHOP.bak.$(date +%s)"

python - <<'PY'
from pathlib import Path
import re

p = Path("lib/pages/eb_shopping_page.dart")
s = p.read_text(encoding="utf-8")

# 1) Legg til dart:async hvis mangler
if "import 'dart:async';" not in s:
    s = "import 'dart:async';\n" + s

# 2) Bytt const PremiumService() -> PremiumService()
s = s.replace("const PremiumService()", "PremiumService()")

# 3) Bytt getIsPremium() -> isPremium()
s = s.replace("getIsPremium()", "isPremium()")

p.write_text(s, encoding="utf-8")
print("✅ eb_shopping_page.dart fikset")
PY


echo "== Fikser premium_page.dart =="
PREM="lib/pages/premium_page.dart"
if [ -f "$PREM" ]; then
  cp "$PREM" "$PREM.bak.$(date +%s)"
  python - <<'PY'
from pathlib import Path

p = Path("lib/pages/premium_page.dart")
s = p.read_text(encoding="utf-8")

# fjern const PremiumService()
s = s.replace("const PremiumService()", "PremiumService()")

# bytt setIsPremium -> setPremiumForDebug
s = s.replace("setIsPremium(", "setPremiumForDebug(")

p.write_text(s, encoding="utf-8")
print("✅ premium_page.dart fikset")
PY
fi


echo "== Format + Analyze =="
dart format lib >/dev/null
flutter analyze || true

echo "🚀 Ferdig. Restart web-server."
