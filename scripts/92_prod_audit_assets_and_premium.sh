#!/usr/bin/env bash
set -euo pipefail

echo "== C1: Verifiser pubspec assets entries =="
grep -n "assets/" pubspec.yaml || true

echo
echo "== C2: Finn shopping json i repo =="
ls -lah assets | sed -n '1,120p'

echo
echo "== C3: Bygg web release for å se at assets blir med =="
flutter build web --release >/dev/null

echo
echo "== C4: Sjekk at shopping json faktisk ligger i build/web/assets =="
find build/web/assets -maxdepth 3 -type f | grep -E "eb\.shopping|offers|json" || true

echo
echo "== C5: Quick grep for PremiumService API i codebase =="
grep -RIn "class PremiumService|isPremium|freeLimit|showBadges" lib | head -n 80 || true

echo
echo "✅ C ferdig"
