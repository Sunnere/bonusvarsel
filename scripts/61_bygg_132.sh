#!/bin/bash
# 61: Bygg 1.3.2+40 for App Store (ipa) og Google Play (aab). Stopper ved feil.
# Kjør: bash scripts/61_bygg_132.sh   (REPO=... for annen mappe)
set -euo pipefail
REPO="${REPO:-$HOME/bonusvarsel}"
cd "$REPO"

VER=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
[ "$VER" = "1.3.2+40" ] || { echo "❌ pubspec har versjon $VER, forventet 1.3.2+40"; exit 1; }
echo "== Bygger $VER"

flutter pub get
OUT=$(flutter analyze --no-pub 2>&1 || true)
if echo "$OUT" | grep -qE '^\s+error •'; then
  echo "$OUT" | grep -E '^\s+error •'
  echo "❌ analyze fant feil. Avbryter."; exit 1
fi
echo "✅ analyze uten feil"

echo "== iOS (ipa)"
flutter build ipa --release
echo "== Android (aab)"
flutter build appbundle --release

echo
echo "✅ Ferdig. Filer:"
ls -la build/ios/ipa/*.ipa build/app/outputs/bundle/release/app-release.aab
