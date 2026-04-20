#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="lib/pages/eb_shopping_page.dart"

echo "==> patch_779_restore_eb_shopping_from_latest_good_backup"

if [ ! -f "$TARGET" ]; then
  echo "❌ Fant ikke $TARGET"
  exit 1
fi

LATEST_BAK=""

# Foretrekk backup fra før patch_777/778 rotet til recommendation-kortet.
for pattern in \
  "lib/pages/eb_shopping_page.dart.bak_777_*" \
  "lib/pages/eb_shopping_page.dart.bak_776_*" \
  "lib/pages/eb_shopping_page.dart.bak_760_*" \
  "lib/pages/eb_shopping_page.dart.bak_759_*" \
  "lib/pages/eb_shopping_page.dart.bak_758_*" \
  "lib/pages/eb_shopping_page.dart.bak_757_*"
do
  CANDIDATE="$(ls -t $pattern 2>/dev/null | head -1 || true)"
  if [ -n "${CANDIDATE:-}" ]; then
    LATEST_BAK="$CANDIDATE"
    break
  fi
done

if [ -z "$LATEST_BAK" ]; then
  echo "❌ Fant ingen passende backup av eb_shopping_page.dart"
  echo "Sjekk manuelt med:"
  echo "  ls -t lib/pages/eb_shopping_page.dart.bak_* | head -20"
  exit 1
fi

echo "==> Gjenoppretter fra:"
echo "   $LATEST_BAK"

cp "$TARGET" "$TARGET.before_restore_779_$(date +%Y%m%d_%H%M%S)"
cp "$LATEST_BAK" "$TARGET"

echo
echo "==> Verifiserer at anbefalings-patchen er borte"
grep -n "_bestRecommendation\\|_recommendations\\|_openRecommendationPaywall\\|Beste valg akkurat nå\\|Beste valg basert på ditt bruk" "$TARGET" || true

echo
echo "✅ Gjenopprettet $TARGET"
echo
echo "Kjør nå:"
echo "1) flutter analyze"
echo "2) flutter run -d macos"
echo
echo "Hvis grønt nok etter restore, lager vi en NY og tryggere recommendation-wiring patch."
